package Mirror::CPAN;

# An implementation of the Mirror::YAML API for the current CPAN.

use 5.005;
use strict;
use LWP::UserAgent;
use LWP::Online;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

