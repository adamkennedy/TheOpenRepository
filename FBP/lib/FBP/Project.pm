package FBP::Project;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Object';
with    'FBP::Children';

has internationalize => (
	is  => 'ro',
	isa => 'Bool',
);

sub dialogs {
	return grep { 
		Params::Util::_INSTANCE($_, 'FBP::Dialog')
	} @{$_[0]->children}
}

1;
