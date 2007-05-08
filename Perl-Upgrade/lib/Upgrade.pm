package Perl::Upgrade;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Perl::Upgrade::Transform::ExplicitHeredocQuotes ();

1;
