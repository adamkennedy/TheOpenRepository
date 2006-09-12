#!/usr/bin/perl -w

# Compile testing for POE::Declare

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;

ok( $] >= 5.005, "Your perl is new enough" );

# Load the modules
require_ok('POE::Declare');
require_ok('POE::Declare::Meta::Internal' );
require_ok('POE::Declare::Meta::Attribute');
require_ok('POE::Declare::Meta::Param'    );
require_ok('POE::Declare::Meta::Message'  );
require_ok('POE::Declare::Meta::Event'    );

# Check inheritance
ok( POE::Declare::Meta::Internal->isa('POE::Declare::Meta::Slot'),  'Internal isa Slot'  );
ok( POE::Declare::Meta::Attribute->isa('POE::Declare::Meta::Slot'), 'Attribute isa Slot' );
ok( POE::Declare::Meta::Param->isa('POE::Declare::Meta::Slot'),     'Param isa Slot'     );
ok( POE::Declare::Meta::Message->isa('POE::Declare::Meta::Slot'),   'Message isa Slot'   );
ok( POE::Declare::Meta::Event->isa('POE::Declare::Meta::Slot'),     'Event isa Slot'     );

exit(0);
