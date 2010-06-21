package FBP::Project;

use Moose;

our $VERSION = '0.02';

extends 'FBP::Parent';

sub dialogs {
	return grep { 
		Params::Util::_INSTANCE($_, 'FBP::Dialog')
	} @{$_[0]->children}
}

1;
