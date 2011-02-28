package FBP::HtmlWindow;

use Mouse;

our $VERSION = '0.18';

extends 'FBP::Window';

has permission => (
	is  => 'ro',
	isa => 'Str',
	required => 1,
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnHtmlCellClicked => (
	is  => 'ro',
	isa => 'Str',
);

has OnHtmlCellHover => (
	is  => 'ro',
	isa => 'Str',
);

has OnHtmlLinkClicked => (
	is  => 'ro',
	isa => 'Str',
);

1;
