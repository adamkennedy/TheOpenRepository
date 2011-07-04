package FBP::SizerItem;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Object';
with    'FBP::Children';
with    'FBP::SizerItemBase';

has proportion => (
	is  => 'ro',
	isa => 'Int',
);

1;
