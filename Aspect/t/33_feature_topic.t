#!/usr/bin/perl

# Tests that function which operate on the topic variable $_ work correctly

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use Test::NoWarnings;
use Aspect;





######################################################################
# Topic Propogation and Manipulation

SCOPE: {
	package Bar;

	sub around_control {
		$_ += 10;
		return "Topic is $_";
	}

	sub around_matched {
		$_ += 10;
		return "Topic is $_";
	}

	sub around_unmatched {
		$_ += 10;
		return "Topic is $_";
	}

	sub before_control {
		$_ += 100;
		return "Topic is $_";
	}

	sub before_matched {
		$_ += 100;
		return "Topic is $_";
	}

	sub before_unmatched {
		$_ += 100;
		return "Topic is $_";
	}

	sub after_control {
		$_ += 1000;
		return "Topic is $_";
	}

	sub after_matched {
		$_ += 1000;
		return "Topic is $_";
	}

	sub after_unmatched {
		$_ += 1000;
		return "Topic is $_";
	}
}

# Do the functions initially work
$_ = 1;
is( Bar::around_control(), 'Topic is 11',   'around_control ok' );
is( Bar::before_control(), 'Topic is 111',  'before_control ok' );
is( Bar::after_control(),  'Topic is 1111', 'after_control ok'  );

# Set up some null aspects over the matched functions
around { $_->proceed } call 'Bar::around_matched';
around { $_->proceed } call 'Bar::around_unmatched' & wantvoid;
before { } call 'Bar::before_matched';
before { } call 'Bar::before_unmatched' & wantvoid;
after  { } call 'Bar::after_matched';
after  { } call 'Bar::after_unmatched' & wantvoid;

$_ = 2;
is( Bar::around_matched(),   'Topic is 12',   'around_matched ok'   );
is( Bar::around_unmatched(), 'Topic is 22',   'around_unmatched ok' );
is( Bar::before_matched(),   'Topic is 122',  'before_matched ok'   );
is( Bar::before_unmatched(), 'Topic is 222',  'before_unmatched ok' );
is( Bar::after_matched(),    'Topic is 1222', 'after_matched ok'    );
is( Bar::after_unmatched(),  'Topic is 2222', 'after_unmatched ok'  );
