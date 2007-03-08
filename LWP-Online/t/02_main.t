#!/usr/bin/perl

# Main testing for LWP-Online

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use LWP::Online 'online';

ok( defined &online, 'LWP::Online exports the online function' );

# We can't actually be sure if we are online or not currently.
# So as long as calling online never crashes, and returns EITHER
# 1 or '', then it is a success.
diag("Looking for the internet, this may take a few minutes if you are offline.");

my $rv = eval { online() };
is( $@, '', 'Call to online() does not crash' );
ok( ($rv eq '1' or $rv eq ''), "online() returns a valid result '$rv'" );
if ( $rv ) {
	diag("You are online");
} else {
	diag("You are not online");
}
exit(0);
