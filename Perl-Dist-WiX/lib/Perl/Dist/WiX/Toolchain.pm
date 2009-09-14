package Perl::Dist::WiX::Toolchain;

use 5.008001;
use Moose;
use MooseX::NonMoose;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw( Str Int Bool HashRef ArrayRef Maybe );
use English qw( -no_match_vars );
use Carp qw();
use Params::Util qw( _HASH _ARRAY );
use Module::CoreList 2.18 qw();
use IO::Capture::Stdout qw();
use IO::Capture::Stderr qw();

# use Process::Delegatable  qw();
# use Process               qw();
use vars qw(@DELEGATE);

our $VERSION = '1.090_102';
$VERSION = eval { return $VERSION };

extends qw(
  Process::Delegatable
  Process
);

has modules => (
	metaclass => 'Collection::ImmutableHash',
	is        => 'ro',
	isa       => HashRef [ ArrayRef [Str] ],
	builder   => '_modules_build',
	init_arg  => undef,
	provides  => {
		'exists' => '_modules_exists',
		'get'    => '_get_modules',
	},
);

has corelist_version => (
	metaclass => 'Collection::ImmutableHash',
	is        => 'ro',
	isa       => HashRef [Str],
	builder   => '_corelist_version_build',
	init_arg  => undef,
	provides  => {
		'exists' => '_corelist_version_exists',
		'get'    => '_get_corelist_version',
	},
);

has corelist => (
	metaclass => 'Collection::ImmutableHash',
	is        => 'ro',
	isa       => HashRef,
	builder   => '_corelist_build',
	init_arg  => undef,
	lazy      => 1,
	provides  => {
		'exists' => '_corelist_exists',
		'get'    => '_get_corelist',
	},
);

has dists => (
	metaclass => 'Collection::Array',
	is        => 'rw',
	isa       => ArrayRef [Str],
	default   => sub { return [] },
	init_arg  => undef,
	provides  => {
		'push'     => '_push_dists',
		'elements' => 'get_dists',
		'grep'     => '_grep_dists',
		'clear'    => '_empty_dists',
		'count'    => 'dist_count',
	},
);

has perl_version => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_perl_version',
	required => 1,
);

has force => (
	metaclass => 'Collection::ImmutableHash',
	is        => 'ro',
	isa       => HashRef,
	default   => sub { return {} },
	provides  => {
		'exists' => '_force_exists',
		'get'    => '_get_forced_dist',
	},
);

has cpan => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_cpan',
	required => 1,
);

has _delegated => (
	metaclass => 'Bool',
	is        => 'rw',
	isa       => Bool,
	init_arg  => undef,
	default   => sub {0},
	provides  => { 'set' => '_delegate', },
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

	my %modules = (
		'5.008009' => [ qw{
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
			  File::Which
			  Archive::Zip
			  Package::Constants
			  IO::String
			  Archive::Tar
			  Compress::unLZMA
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
			  LWP::UserAgent
			  }
		],
	);
	$modules{'5.010001'} = $modules{'5.008009'};
	$modules{'5.010000'} = $modules{'5.008009'};

	return \%modules;
} ## end sub _modules_build

sub _corelist_version_build {

	my %corelist = (
		'5.008009' => '5.008009',
		'5.010000' => '5.010000',
		'5.010001' => '5.010001',
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
	unless ( $self->_modules_exists( $self->_get_perl_version ) ) {
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version
			  . "' is not supported in $class" );
	}
	unless ( $self->_corelist_version_exists( $self->_get_perl_version ) ) {
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version
			  . "' is not supported in $class" );
	}
	
} ## end sub BUILD

sub prepare {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	$stdout->start;
	$stderr->start;

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
		$stdout->stop;
		$stderr->stop;
		return 1;
	} else {
		$stdout->stop;
		$stderr->stop;
		return q{};
	}
} ## end sub prepare

sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;

	$stdout->start;
	$stderr->start;
	CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
	$CPAN::Config->{'urllist'}    = [ $self->_get_cpan() ];
	$CPAN::Config->{'use_sqlite'} = q[0];
	$stdout->stop;
	$stderr->stop;

	foreach
	  my $name ( @{ $self->_get_modules( $self->_get_perl_version ) } )
	{

		# Shortcut if forced
		if ( $self->_force_exists($name) ) {
			$self->_dist_push( $self->_get_forced_dist($name) );
			next;
		}

		# Get the CPAN object for the module, covering any output.
		$stdout->start;
		$stderr->start;
		my $module = CPAN::Shell->expand( 'Module', $name );
		$stdout->stop;
		$stderr->stop;

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

TODO

=head1 METHODS

TODO

This class is a L<Perl::Dist::WiX::Role::Asset> and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Distribution> object.

It inherits all the params described in the L<Perl::Dist::WiX::Role::Asset> 
C<new> method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the name of the package for the purposes
of identification.

This should match the name of the Perl distribution without any version
numbers. For example, "File-Spec" or "libwww-perl".

Alternatively, the C<name> param can be a CPAN path to the distribution
such as shown in the synopsis.

In this case, the url to fetch from will be derived from the name.

=item force

Unlike in the CPAN client installation, in which all modules MUST pass
their tests to be added, the secondary method allows for cases where
it is known that the tests can be safely "forced".

The optional boolean C<force> param allows you to specify that the tests
should be skipped and the module installed without validating it.

=item automated_testing

Many modules contain additional long-running tests, tests that require
additional dependencies, or have differing behaviour when installing
in a non-user automated environment.

The optional C<automated_testing> param lets you specify that the
module should be installed with the B<AUTOMATED_TESTING> environment
variable set to true, to make the distribution behave properly in an
automated environment (in cases where it doesn't otherwise).

=item release_testing

Some modules contain release-time only tests, that require even heavier
additional dependencies compared to even the C<automated_testing> tests.

The optional C<release_testing> param lets you specify that the module
tests should be run with the additional C<RELEASE_TESTING> environment
flag set.

By default, C<release_testing> is set to false to squelch any accidental
execution of release tests when L<Perl::Dist::WiX> itself is being tested
under C<RELEASE_TESTING>.

=item makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=item buildpl_param

Some distributions require you to pass additional non-standard
parameters when you invoke "perl Build.PL".

The optional C<buildpl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Build.PL.

=back

The C<new> method returns a B<Perl::Dist::WiX::Asset::Distribution> object,
or throws an exception on error.

=head2 install

The install method installs the website link described by the
B<Perl::Dist::WiX::Asset::Website> object and returns a file
that was installed as a L<File::List::Object> object.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut


