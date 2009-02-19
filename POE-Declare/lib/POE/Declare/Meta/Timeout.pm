package POE::Declare::Meta::Timeout;

use 5.008007;
use strict;
use POE::Declare::Meta::Event ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'POE::Declare::Meta::Event';
}

1;
