#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
use Module::Plan::Base;





#####################################################################
# Constructor Testing

# ... with the full name
SCOPE: {
	my $plan = Module::Plan::Base->read( catfile('t','data','default.pip') );
	isa_ok( $plan, 'Module::Plan::Lite' );

}
