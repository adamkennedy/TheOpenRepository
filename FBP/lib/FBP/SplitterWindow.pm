package FBP::SplitterWindow;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Window';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has splitmode => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashgravity => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashpos => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashsize => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has min_pane_size => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has OnSplitterSashPosChanging => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterSashPosChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterUnsplit => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterDClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
