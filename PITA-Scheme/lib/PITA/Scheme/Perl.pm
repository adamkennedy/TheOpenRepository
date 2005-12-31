package PITA::Scheme::Perl;

# Base class for all schemes working with Perl-like distributions.
# Provides bits of common functionality.

use strict;
use base 'PITA::Scheme';
use Carp             ();
use File::Spec       ();
use Archive::Extract ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Generic Constructor

# Do the extra common checks we couldn't do in the main class
sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Can we locate the package?
	my $filename = $self->request->filename;
	$self->{archive} = File::Spec->catfile( $self->{injector}, $filename );
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
	@{$_[0]->{extract_files}};
}





#####################################################################
# PITA::Scheme Methods

sub prepare_package {
	my $self = shift;
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

	# Look for a single subdirectory and descend if needed
	$self;
}

1;
