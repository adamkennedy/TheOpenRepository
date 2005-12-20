package PITA::TestHarness;

use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Get and check the directory
	my $dir = shift;
	unless ( defined $dir and ! ref $dir and length $dir ) {
		Carp::croak("Did not provide a directory name");
	}
	unless ( -d $dir and -r $dir ) {
		Carp::croak("'$dir' is not a readable directory");
	}

	# Create the object
	my $self = bless {
		dir => $dir,
		}, $class;

	$self;
}

sub dir { $_[0]->{dir} }





#####################################################################
# Support Methods

sub _chdir {
	my $self = shift;
	chdir $_[0] or Carp::croak("Failed to chdir to '$_[0]'");
	1;
}

1;
