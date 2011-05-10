package FBP::Project;

use Mouse;

our $VERSION = '0.27';

extends 'FBP::Object';
with    'FBP::Children';

has internationalize => (
	is  => 'ro',
	isa => 'Bool',
);

no Mouse;





######################################################################
# Convenience Methods

sub dialogs {
	return grep { 
		Params::Util::_INSTANCE($_, 'FBP::Dialog')
	} @{$_[0]->children}
}

1;
