package POE::Declare::Meta::Internal;

use 5.008007;
use strict;
use POE::Declare::Meta::Slot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'POE::Declare::Meta::Slot';
}

1;
