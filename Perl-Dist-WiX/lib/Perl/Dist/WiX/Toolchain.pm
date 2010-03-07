package Perl::Dist::WiX::Toolchain;

use 5.008001;
use Moose 0.90;
use MooseX::NonMoose;
use MooseX::Types::Moose qw( Str Int Bool HashRef ArrayRef Maybe );
use Moose::Util::TypeConstraints;
use English qw( -no_match_vars );
use Carp qw();
use Params::Util qw( _HASH _ARRAY );
use Module::CoreList 2.18 qw();
use IO::Capture::Stdout qw();
use IO::Capture::Stderr qw();
use vars qw(@DELEGATE);

our $VERSION = '1.102_101';
$VERSION =~ s/_//ms;

extends qw(
  Process::Delegatable
  Process
);

has modules => (
	traits   => ['Hash'],
	is       => 'ro',
	isa      => HashRef [ ArrayRef [Str] ],
	builder  => '_modules_build',
	lazy     => 1,
	init_arg => undef,
	handles  => {
		'_modules_exists' => 'exists',
		'_get_modules'    => 'get',
	},
);

has corelist_version => (
	traits   => ['Hash'],
	is       => 'ro',
	isa      => HashRef [Str],
	builder  => '_corelist_version_build',
	init_arg => undef,
	handles  => {
		'_corelist_version_exists' => 'exists',
		'_get_corelist_version'    => 'get',
	},
);

has corelist => (
	traits   => ['Hash'],
	is       => 'ro',
	isa      => HashRef,
	builder  => '_corelist_build',
	init_arg => undef,
	lazy     => 1,
	handles  => {
		'_corelist_exists' => 'exists',
		'_get_corelist'    => 'get',
	},
);

has dists => (
	traits   => ['Array'],
	is       => 'ro',
	isa      => ArrayRef [Str],
	default  => sub { return [] },
	init_arg => undef,
	handles  => {
		'_push_dists'  => 'push',
		'get_dists'    => 'elements',
		'_grep_dists'  => 'grep',
		'_empty_dists' => 'clear',
		'dist_count'   => 'count',
	},
);

has perl_version => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_perl_version',
	required => 1,
);

has force => (
	traits  => ['Hash'],
	is      => 'ro',
	isa     => HashRef,
	default => sub { return {} },
	handles => {
		'_force_exists'    => 'exists',
		'_get_forced_dist' => 'get',
	},
);

has cpan => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_cpan',
	required => 1,
);

has bits => (
	is  => 'ro',                       # Integer 32/64
	isa => subtype(
		'Int' => where {
			$_ == 32 or $_ == 64;
		},
		message {
			'Must be a 32 or 64-bit perl';
		},
	),
	required => 1,
);

has _delegated => (
	traits   => ['Bool'],
	is       => 'ro',
	isa      => Bool,
	init_arg => undef,
	default  => 0,
	handles  => { '_delegate' => 'set', },
);

# Process::Delegatable sets this, this attribute just
# defines how to get at it.
has errstr => (
	is       => 'ro',
	isa      => Maybe [Str],
	init_arg => undef,
	default  => undef,
	reader   => 'get_error',
);

BEGIN {
	@DELEGATE = ();

	# Automatically handle delegation within the test suite
	if ( $ENV{HARNESS_ACTIVE} ) {
		require Probe::Perl;
		@DELEGATE = ( Probe::Perl->find_perl_interpreter, '-Mblib', );
	}
}

sub _modules_build {
	my $self = shift;

	my @modules_list = (qw {
		ExtUtils::MakeMaker
		File::Path
		ExtUtils::Command
		Win32API::File
		ExtUtils::Install
		ExtUtils::Manifest
		Test::Harness
		Test::Simple
		ExtUtils::CBuilder
		ExtUtils::ParseXS
		version
		Scalar::Util
		Compress::Raw::Zlib
		Compress::Raw::Bzip2
		IO::Compress::Base
		Compress::Bzip2
		IO::Zlib
		File::Spec
		File::Temp
		Win32::WinError
		Win32API::Registry
		Win32::TieRegistry
		File::HomeDir
		IPC::Run3
		Probe::Perl
		Test::Script
		File::Which
		Archive::Zip
		Package::Constants
		IO::String
		Archive::Tar}); 

	push @modules_list, 'Compress::unLZMA' if 32 == $self->bits();
	
	push @modules_list, qw{
		Win32::UTCFileTime
		Parse::CPAN::Meta
		YAML
		Net::FTP
		Digest::MD5
		Digest::SHA1
		Digest::SHA
		Module::Build
		Term::Cap
		CPAN
		Term::ReadKey
		Term::ReadLine::Perl
		Text::Glob
		Data::Dumper
		URI
		HTML::Tagset
		HTML::Parser
		LWP::UserAgent};

	my %modules = (
		'5.008009' => \@modules_list,
	);
	$modules{'5.010000'} = $modules{'5.008009'};
	$modules{'5.010001'} = $modules{'5.008009'};
	$modules{'5.011001'} = $modules{'5.008009'};
	$modules{'5.011005'} = $modules{'5.008009'};

	return \%modules;
} ## end sub _modules_build

sub _corelist_version_build {

	my %corelist = (
		'5.008009' => '5.008009',
		'5.010000' => '5.010000',
		'5.010001' => '5.010001',
		'5.011001' => '5.011001',
		'5.011005' => '5.011005',
	);

	return \%corelist;
}

sub _corelist_build {
	my $self = shift;

	# Confirm we can find the corelist for the Perl version
	my $corelist_version =
	  $self->_get_corelist_version( $self->_get_perl_version() );
	my $corelist = $Module::CoreList::version{$corelist_version}
	  || $Module::CoreList::version{ $corelist_version + 0 };

	# TODO: Use exceptions instead.
	unless ( _HASH($corelist) ) {
		Carp::croak( 'Failed to find module core versions for Perl '
			  . $self->_get_perl_version() );
	}

	return $corelist;
} ## end sub _corelist_build

#####################################################################
# Constructor and Accessors

sub BUILD {
	my $self  = shift;
	my $class = ref $self;

	# TODO: Use exceptions instead.
	unless ( $self->_modules_exists( $self->_get_perl_version() ) ) {
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version()
			  . "' is not supported in $class" );
	}
	unless ( $self->_corelist_version_exists( $self->_get_perl_version() ) )
	{
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version()
			  . "' is not supported in $class" );
	}

} ## end sub BUILD

sub prepare {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new();
	my $stderr = IO::Capture::Stderr->new();
	$stdout->start();
	$stderr->start();

	# Load the CPAN client
	require CPAN;
	CPAN->import();

	# Load the latest index
	if (
		eval {
			local $SIG{__WARN__} = sub {1};
			CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
			$CPAN::Config->{'urllist'}    = [ $self->_get_cpan() ];
			$CPAN::Config->{'use_sqlite'} = q[0];
			CPAN::Index->reload;
			1;
		} )
	{
		$stdout->stop();
		$stderr->stop();
		return 1;
	} else {
		$stdout->stop();
		$stderr->stop();
		return q{};
	}
} ## end sub prepare

sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new();
	my $stderr = IO::Capture::Stderr->new();

	$stdout->start();
	$stderr->start();
	CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
	$CPAN::Config->{'urllist'}    = [ $self->_get_cpan() ];
	$CPAN::Config->{'use_sqlite'} = q[0];
	$stdout->stop();
	$stderr->stop();

	foreach
	  my $name ( @{ $self->_get_modules( $self->_get_perl_version ) } )
	{

		# Shortcut if forced
		if ( $self->_force_exists($name) ) {
			$self->_dist_push( $self->_get_forced_dist($name) );
			next;
		}

		# Get the CPAN object for the module, covering any output.
		$stdout->start();
		$stderr->start();
		my $module = CPAN::Shell->expand( 'Module', $name );
		$stdout->stop();
		$stderr->stop();

		unless ($module) {
			## no critic (RequireCarping RequireUseOfExceptions)
			die "Failed to find '$name'";
		}

		# Ignore modules that don't need to be updated
		my $core_version = $self->_get_corelist($name);
		if ( defined $core_version and $core_version =~ /_/ms ) {

			# Sometimes, the core contains a developer
			# version. For the purposes of this comparison
			# it should be safe to "round down".
			$core_version =~ s{_.+}{}ms;
		}
		my $cpan_version = $module->cpan_version;
		unless ( defined $cpan_version ) {
			next;
		}
		if ( defined $core_version and $core_version >= $cpan_version ) {
			next;
		}

		# Filter out already seen dists
		my $file = $module->cpan_file;
		$file =~ s{\A [A-Z] / [A-Z][A-Z] /}{}msx;
		$self->_push_dists($file);
	} ## end foreach my $name ( @{ $self...})

	# Remove duplicates
	my %seen = ();
	my @dists = $self->_grep_dists( sub { !$seen{$_}++ } );

	$self->_empty_dists();
	$self->_push_dists(@dists);

	return 1;
} ## end sub run

sub delegate {
	my $self = shift;
	unless ( $self->_delegated() ) {
		$self->SUPER::delegate(@DELEGATE);
		$self->_delegate();
	}
	return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Toolchain - TO BE DOCUMENTED

=head1 SYNOPSIS

  my $toolchain = Perl::Dist::WiX::Toolchain->new(
    ...
  );

=head1 DESCRIPTION

TODO: Document

=head1 METHODS

TODO: Document

=head2 new

TODO: Document

=head2 prepare

TODO: Document

=head2 run

TODO: Document

=head2 get_dists

TODO: Document

=head2 dist_count

TODO: Document

=head2 get_error

TODO: Document

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Module::CoreList>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
