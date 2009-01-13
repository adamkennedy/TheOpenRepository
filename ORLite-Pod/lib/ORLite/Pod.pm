package ORLite::Pod;

use 5.006;
use strict;
use Carp         ();
use File::Spec   ();
use Params::Util qw{_CLASS};
use ORLite       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless (
		_CLASS($self->from)
		and
		$self->from->can('orlite')
	) {
		die("Did not provide a 'from' ORLite root class to generate from");
	}
	my $to = $self->to;
	unless ( $self->to ) {
		die("Did not provide a 'to' lib directory to write into");
	}
	unless ( -d $self->to ) {
		die("The 'to' lib directory '$to' does not exist");
	}
	unless ( -w $self->to ) {
		die("No permission to write to directory '$to'");
	}

	return $self;
}

sub from {
	$_[0]->{from};
}

sub to {
	$_[0]->{to};
}

sub run {
	my $self = shift;

}

1;
