package XRC::Dialog;

use Moose;
use Moose::Util::TypeConstraints;

enum 'Style' => qw{
	wxCAPTION
	wxCLOSE_BOX
	wxDEFAULT_DIALOG_STYLE
	wxDIALOG_NO_PARENT
	wxMAXIMIZE_BOX
	wxMINIMIZE_BOX
	wxRESIZE_BORDER
	wxSTAY_ON_TOP
	wxSYSTEM_MENU
};

extends 'XRC::Object';

has children => (
	is      => 'rw',
	isa     => "ArrayRef[XRC::Object]",
	default => sub { [ ] },
);

has style => (
	is  => 'rw',
	isa => 'ArrayRef[Style]',
);

has title => (
	is  => 'rw',
	isa => 'Str',
);

has size => (
	is      => 'rw',
	isa     => 'XRC::Size',
	default => sub {
		XRC::Size->new(
			width  => -1,
			height => -1,
		)
	},
);

sub add_object {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'XRC::Object') ) {
		die("Can only add a 'XRC::Object' object");
	}
	my $objects = $self->children;
	push @$objects, shift;
	return 1;
}

1;
