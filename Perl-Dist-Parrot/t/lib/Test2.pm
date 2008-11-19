package t::lib::Test2;

use strict;
use Perl::Dist::Parrot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.10';
	@ISA     = 'Perl::Dist::Parrot';
}





#####################################################################
# Main Methods

sub trace { Test::More::diag($_[1]) }

1;
