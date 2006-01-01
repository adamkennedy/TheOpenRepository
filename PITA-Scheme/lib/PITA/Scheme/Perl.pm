package PITA::Scheme::Perl;

# Base class for all schemes working with Perl-like distributions.
# Provides bits of common functionality.

use strict;
use base 'PITA::Scheme';
use Carp             ();
use File::Spec       ();
use Params::Util     '_INSTANCE';
use Archive::Extract ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Generic Constructor

# Do the extra common checks we couldn't do in the main class
sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Can we locate the package?
	my $filename = $self->request->filename;
	$self->{archive} = File::Spec->catfile( $self->injector, $filename );
	unless ( -f $self->{archive} ) {
		Carp::croak('Failed to find package $filename in injector');
	}

	$self;
}

sub archive {
	$_[0]->{archive};
}

sub extract_path {
	$_[0]->{extract_path};
}

sub extract_files {
	my $files = $_[0]->{extract_files};
	$files ? @$files : ();
}

sub platform {
	$_[0]->{platform};
}





#####################################################################
# PITA::Scheme Methods

sub prepare_package {
	my $self = shift;
	$self->SUPER::prepare_package(@_);
	return 1 if $self->{extract_files};

	# Extract the package to the working directory
	my $archive = Archive::Extract->new( archive => $self->archive )
		or Carp::croak("Package is not an archive, or not extractable");

	# Extract the archive to the working directory
	local $Archive::Extract::WARN = 0;
	my $ok = $archive->extract( to => $self->workarea )
		or Carp::croak("Error extracting package: "
			. $archive->error );

	# Save the list of files
	$self->{extract_path}  = $archive->extract_path;
	$self->{extract_files} = $archive->files;
	### For now this list is unreliable and inconsistent.

	# Look for a single subdirectory and descend if needed
	$self;
}

sub prepare_environment {
	my $self = shift;
	unless ( $self->extract_path ) {
		Carp::croak("Cannot call prepare_environment without extracting pachage");
	}

	# Change to the extraction directory
	unless ( chdir $self->extract_path ) {
		Carp::croak("Failed to change to extract_path for execution");
	}

	# Set any environment variables from the Request
	### Not supported by PITA::Report::Request yet

	# Save the platform configuration
	$self->{platform} = PITA::Report::Platform->current;
	unless ( _INSTANCE($self->{platform}, 'PITA::Report::Platform') ) {
		Carp::croak("Failed to capture platform information");
	}

	# Apply private changes to control the testing environment
	### Not implemented

	1;
}






#####################################################################
# PITA::Scheme::Perl Methods

# Mainly a convenience for now.
sub workarea_file {
	my $self = shift;

	# If the package has been extracted, prefer its
	# interpretation of being where the workarea is.
	my $workarea = defined $self->extract_path
		? $self->extract_path
		: $self->workarea;
	File::Spec->catfile( $workarea, shift );
}

1;
