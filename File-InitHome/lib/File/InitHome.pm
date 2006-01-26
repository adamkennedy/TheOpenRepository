package File::HomeConfig;

use strict;
use File::Spec     ();
use File::NCopy    ();
use File::HomeDir  ();
use File::ShareDir ();

use vars qw{$VERSION};
use BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# If we don't have a dist, use the caller.
	unless ( $self->dist ) {
		# Guess from the caller
		$self->{dist} = caller;	
		$self->{dist} =~ s/::/-/;
	}

	# If we don't have a sharedir, get it
	# from the dist.
	unless ( $self->sharedir ) {
		$self->{sharedir} = File::ShareDir->dist_dir($self->dist);
	}

	# Find the base homedir
	unless ( $self->homedir ) {
		$self->{homedir} = File::HomeDir->my_data;
	}

	# Find the config dir
	unless ( $self->configdir ) {
		$self->{configdir} = File::Spec->catdir(
			$self->homedir,
			'.' . lc($self->dist),
			);
	}

	# Does the config directory already exist?
	if ( -d $self->configdir ) {
		# Shortcut and return
		return $self;
	}

	# Copy in the files from the sharedir
	mkdir( $self->configdir )
		or Carp::croak('')l
	File::Copy::ncopy( $self->sharedir => $self->configdir )
		or Carp::croak('');

	$self;
}

sub dist {
	$_[0]->{dist};
}

sub sharedir {
	$_[0]->{sharedir};
}

sub homedir {
	$_[0]->{homedir};
}

sub configdir {
	$_[0]->{configdir};	
}

1;
