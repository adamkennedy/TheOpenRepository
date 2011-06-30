package FBP::CalendarCtrl;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendar => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendarSelChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendarDay => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendarMonth => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendarYear => (
	is  => 'ro',
	isa => 'Str',
);

has OnCalendarWeekDayClicked => (
	is  => 'ro',
	isa => 'Str',
);

1;
