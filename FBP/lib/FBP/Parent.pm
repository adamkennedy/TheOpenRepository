package FBP::Parent;

use Moose;
use Moose::Util::TypeConstraints;
use Params::Util ();

extends 'FBP::Object';

has children => (
	is      => 'rw',
	isa     => "ArrayRef[FBP::Object]",
	default => sub { [ ] },
);

sub add_object {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'FBP::Object') ) {
		die("Can only add a 'FBP::Object' object");
	}
	my $objects = $self->children;
	push @$objects, shift;
	return 1;
}

1;
