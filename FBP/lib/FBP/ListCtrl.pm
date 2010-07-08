package FBP::ListCtrl;

use Mouse;

our $VERSION = '0.09';

extends 'FBP::Window';
with    'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
