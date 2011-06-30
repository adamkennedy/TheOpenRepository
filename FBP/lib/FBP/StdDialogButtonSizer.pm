package FBP::StdDialogButtonSizer;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Sizer';





######################################################################
# Properties

has OK => (
	is  => 'ro',
	isa => 'Bool',
);

has Yes => (
	is  => 'ro',
	isa => 'Bool',
);

has Save => (
	is  => 'ro',
	isa => 'Bool',
);

has Apply => (
	is  => 'ro',
	isa => 'Bool',
);

has No => (
	is  => 'ro',
	isa => 'Bool',
);

has Cancel => (
	is  => 'ro',
	isa => 'Bool',
);

has Help => (
	is  => 'ro',
	isa => 'Bool',
);

has ContextHelp => (
	is  => 'ro',
	isa => 'Bool',
);





######################################################################
# Events

has OnOKButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnYesButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnSaveButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnApplyButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnNoButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnCancelButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnHelpButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnContextHelpButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
