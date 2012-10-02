package ADAMK::Release;

use 5.10.0;
use strict;
use warnings;
use Carp                          ();
use File::Spec::Functions    0.80 ':ALL';
use File::Slurp           9999.19 ();
use File::Find::Rule         0.32 ();
use File::Flat                    ();
use Params::Util             1.00 ':ALL';
use GitHub::Extract          0.01 ();
use Module::Extract::VERSION 1.01 ();

our $VERSION = '0.01';

use Object::Tiny 1.01 qw{
	module
	github
};





######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check module
	unless ( _CLASS($self->module) ) {
		$self->error("Missing or invalid module");
	}

	# Inflate and check the github object
	if ( Params::Util::_HASH($self->github) ) {
		$self->{github} = GitHub::Extract->new( %{$self->github} );
	}
	unless ( Params::Util::_INSTANCE($self->github, 'GitHub::Extract')) {
		$self->error("Missing or invalid GitHub specification");
	}

	return $self;
}





######################################################################
# Command Methods

sub run {
	my $self = shift;

	# Export from GitHub and change to the directory
	my $pushd = $self->github->extract;
	unless ( $pushd ) {
		$self->error(
			"Failed to download and extract %s: %s",
			$self->github->url,
			$self->github->error,
		);
	}





	# Validation Phase
	unless ( $self->dist_version ) {
		$self->error("Failed to find version number in $file");
	}
	unless ( $self->makefile_pl or $self->build_pl ) {
		$self->error("Failed to find Makefile.PL or Build.PL");
	}





	# Assembly Phase
	if ( -f $self->dist_manifest_add ) {

	}
}





######################################################################
# Content and Scanning Methods

sub makefile_pl {
	my $self = shift;
	my $file = $self->dist_makefile_pl;
	return undef unless -f $file;
	return File::Slurp::read_file($file);
}

sub build_pl {
	my $self = shift;
	my $file = $self->dist_build_pl;
	return undef unless -f $file;
	return File::Slurp::read_file($file);
}

sub module_version {
	my $self = shift;
	unless ( $self->{module_version} ) {
		my $file    = $self->module_pm;
		my $version = Module::Extract::VERSION->parse_version_safely($file);
		unless ( $version and $version ne 'undef' ) {
			return undef;
		}
		$self->{module_version} = $version;
	}
	return $self->{module_version};
}

sub find_ppport {
	File::Find::Rule->name('*.xs')->file->grep(qr/\bppport\.h\b/);
}

sub find_files {
	File::Find::Rule->file;
}

sub find_0644 {
	File::Find::Rule->name(qw{
		Changes
		Makefile.PL
		META.yml
		*.t
		*.pm
		*.pod
	} )->file;
}

sub find_executable {
	File::Find::Rule->name('*.exe')->not_executable->file;
}

sub find_localize {
	File::Find::Rule->file->not_binary->writable;
}

sub file_localize {
	File::LocalizeNewlines->new(
		filter  => $_[0]->find_localize,
		verbose => 1,
	);
}





######################################################################
# Paths and Files

sub dist {
	my $self   = shift;
	my $dist = $self->module;
	$dist =~ s/::/-/g;
	return $dist;
}

sub dist_tardist {
	$_[0]->dist_file;
}

sub dist_file {
	$_[0]->dist . '-' . $_[0]->dist_version . '.tar.gz';
}

sub dist_version {
	$_[0]->module_version;
}

sub dist_makefile_pl {
	'Makefile.PL';
}

sub dist_build_pl {
	'Build.PL';
}

sub dist_changes {
	'Changes';
}

sub dist_license {
	'LICENSE';
}

sub dist_readme {
	'README';
}

sub dist_meta_yml {
	'META.yml';
}

sub dist_manifest {
	'MANIFEST';
}

sub dist_manifest_skip {
	'MANIFEST.SKIP';
}

sub dist_manifest_add {
	'MANIFEST.SKIP.add';
}

sub dist_ppport {
	'ppport.h';
}

sub dist_t {
	't';
}

sub dist_data {
	catdir('t', 'data');
}

sub dist_99_author {
	catfile('t', '99_author.t');
}

sub dist_xt {
	'xt';
}

sub module_pm {
	catfile( 'lib', $_[0]->module_subpath ) . '.pm';
}

sub module_pod {
	catfile( 'lib', $_[0]->module_subpath ) . '.pod';
}

sub module_subpath {
	catdir( split /::/, $_[0]->module );
}

sub shared_manifest_skip {
	catfile( $_[0]->shared_dir, 'MANIFEST.SKIP' );
}

sub shared_license {
	catfile( $_[0]->shared_dir, 'LICENSE' );
}

sub shared_dir {
	File::ShareDir::dist_dir('ADAMK-Release')
	or $_[0]->error("Failed to find share directory");	
}




######################################################################
# Support Methods

sub sudo {
	my $self = shift;
	my $cmd  = shift;
	my $env  = $self->env(
		ADAMK_RELEASE     => 1,
		RELEASE_TESTING   => $ENV{RELEASE_TESTING}   ? 1 : 0,
		AUTOMATED_TESTING => $ENV{AUTOMATED_TESTING} ? 1 : 0,
	);
	print "> (sudo) $cmd\n" if 0; # $VERBOSE;
	my $sudo = $self->bin_sudo;
	my $rv   = ! system( "$sudo bash -c '$env $cmd'" );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	$self->error($_[0]);
}

sub shell {
	my $self = shift;
	my $cmd  = shift;
	my $env  = $self->env(
		ADAMK_RELEASE     => 1,
		RELEASE_TESTING   => $ENV{RELEASE_TESTING}   ? 1 : 0,
		AUTOMATED_TESTING => $ENV{AUTOMATED_TESTING} ? 1 : 0,
	);
	print "> $cmd\n" if 0; # $VERBOSE;
	my $rv = ! system( "$env $cmd" );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	die $_[0];
}

sub env {
	my $self = shift;
	my %env  = @_;
	join ' ', map { "$_=$env{$_}" } sort keys %env;
}

sub copy {
	my $self = shift;
	my $from = shift;
	my $to   = shift;
	File::Flat->copy( $from => $to ) and return 1;
	$self->error("Failed to copy '$from' to '$to'");
}

sub move {
	my $self = shift;
	my $from = shift;
	my $to   = shift;
	File::Flat->copy( $from => $to ) and return 1;
	$self->error("Failed to move '$from' to '$to'");
}

sub remove {
	my $path = shift;
	if ( -e $path ) {
		sudo( "rm -rf $path" );
		if ( -e $path ) {
			die "Failed to remove '$path'";
		}
	}
	return 1;
}

# Is a particular program installed, and where
sub which {
	my $self    = shift;
	my $program = shift;
	my ($location) = (`which $program`);
	chomp $location;
	unless ( $location ) {
		$self->error("Can't find the required program '$program'. Please install it");
	}
	unless ( -r $location and -x $location ) {
		$self->error("The required program '$program' is installed, but I do not have permission to read or execute it");
	}
	return $location;
}

sub error {
	my $self    = shift;
	my $message = sprintf(@_);
	Carp::croak($message);
}

1;
