package Module::Inspector;

use strict;
use Carp       ();
use File::Spec ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Have we been given a directory
	unless ( -d $self->{root} ) {
		Carp::croak("Missing or invalid module root $self->{root}");
	}

	# Auto-detect version control
	unless ( defined $self->version_control ) {
		$self->{version_control} = $self->_version_control;
	}

	$self;
}

sub root {
	$_[0]->{root};
}

sub version_control {
	$_[0]->{version_control};
}





#####################################################################
# Version Control Detection

sub _version_control {
	my $self = shift;

	# Are we in a subversion checkout
	if ( -d $self->_path_svn_dir ) {
		return 'svn';
	}

	# Are we in a CVS checkout
	if ( -f $self->_path_cvs_repository_file ) {
		return 'cvs';
	}

	# Otherwise, we don't know yet
	'';
}

sub _path_cvs_repository_file {
	File::Spec->catfile( $self->root, 'CVS', 'Repository' );
}

sub _path_svn_dir {
	File::Spec->catdir( $self->root, '.svn' );
}





#####################################################################
# Installer Detection

sub 
1;
