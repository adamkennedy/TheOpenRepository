package Mirror::CPAN;

use 5.00505;
use strict;
use Mirror::JSON;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.04_02';
	@ISA     = 'Mirror::JSON';
}

sub filename {
	return 'modules/07mirror.json';
}

1;
