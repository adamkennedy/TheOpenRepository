package Perl::Dist::Util::Toolchain;

use 5.005;
use strict;
use Carp 'croak';
use Params::Util '_HASH', '_ARRAY';
use Module::CoreList    ();
use IO::Capture::Stdout ();
use IO::Capture::Stderr ();
use base 'Process::Delegatable',
         'Process::Storable',
         'Process';

use vars qw{$VERSION @DELEGATE};
BEGIN {
	$VERSION  = '0.90_02';
	@DELEGATE = ();
}

my %MODULES = (
	'5.008008' => [ qw{
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
		IO::Compress::Base
		Compress::Raw::Zlib
		Compress::Raw::Bzip2
		IO::Compress::Zip
		IO::Compress::Bzip2
		Compress::Zlib
		Compress::Bzip2
		IO::Zlib
		File::Spec
		File::Temp
		Win32API::Registry
		Win32::TieRegistry
		File::HomeDir
		File::Which
		Archive::Zip
		Archive::Tar
		YAML
		Net::FTP
		Digest::MD5
		Digest::SHA1
		Digest::SHA
		Module::Build
		Term::Cap
		CPAN
		Term::ReadLine::Perl
	} ],
);
$MODULES{'5.010000'} = $MODULES{'5.008008'};





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the Perl version
	unless ( defined $self->perl_version ) {
		croak("Did not provide a perl_version param");
	}
	unless ( $MODULES{$self->perl_version} ) {
		croak("Perl version '" . $self->perl_version . "' is not supported in $class");
	}

	# Populate the modules array if needed
	unless ( _ARRAY($self->{modules}) ) {
		$self->{modules}  = $MODULES{$self->perl_version};
	}

	# Confirm we can find the corelist for the Perl version
	$self->{corelist} = $Module::CoreList::version{$self->perl_version}
	                 || $Module::CoreList::version{$self->perl_version+0};
	unless ( _HASH($self->{corelist}) ) {
		croak("Failed to find module core versions for Perl " . $self->perl_version);
	}

	# Create the distribution array
	$self->{dists} = [];

	return $self;
}

sub perl_version {
	$_[0]->{perl_version};
}

sub modules {
	@{$_[0]->{modules}};
}

sub dists {
	@{$_[0]->{dists}};
}

sub errstr {
	$_[0]->{errstr};
}

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
	SCOPE: {
		local $SIG{__WARN__} = sub { 1 };
		CPAN::Index->reload;
	}

	$stdout->stop;
	$stderr->stop;
	return 1;
}

sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	$stdout->start;
	$stderr->start;
	
	# Find the module
	my %seen = ();
	my $core = delete $self->{corelist};
	foreach my $name ( @{$self->{modules}} ) {
		my $module = CPAN::Shell->expand('Module', $name);
		unless ( $module ) {
			$self->{errstr} = "Failed to find '$name'";
			return 0;
		}

		# Ignore modules that don't need to be updated
		my $core_version = $core->{$name};
		if ( defined $core_version and $core_version =~ /_/ ) {
			# Sometimes, the core contains a developer
			# version. For the purposes of this comparison
			# it should be safe to "round down".
			$core_version =~ s/_.+$//;
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
		$file =~ s/^[A-Z]\/[A-Z][A-Z]\///;
		next if $seen{$file}++;

		push @{$self->{dists}}, $file;
	}

	# Free up stdout/stderr for normal output again
	$stdout->stop;
	$stderr->stop;

	return 1;
}

sub delegate {
	return shift->SUPER::delegate( @DELEGATE );
}

1;

