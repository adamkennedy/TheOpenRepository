package FBP::ComboBox;

use Moose;

our $VERSION = '0.04';

extends 'FBP::Window';
with    'FBP::Control';

has value => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);
	
1;
