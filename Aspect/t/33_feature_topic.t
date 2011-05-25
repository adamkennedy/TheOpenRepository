#!/usr/bin/perl

# Tests that function which operate on the topic variable $_ work correctly

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use Test::NoWarnings;
use Aspect;





######################################################################
# Topic Propagation

SCOPE: {
	package Foo;

	sub around_topic {
		return "Topic is $_";
	}

	sub before_topic {
		return "Topic is $_";
	}

	sub after_topic {
		return "Topic is $_";
	}
}

# Do the functions initiall work
$_ = 'test1';
is( Foo::around_topic(), 'Topic is test1', 'around_topic unhooked ok' );
is( Foo::before_topic(), 'Topic is test1', 'before_topic unhooked ok' );
is( Foo::after_topic(),  'Topic is test1', 'after_topic unhooked ok' );

# Set up some null aspects over the topic functions
before { } call 'Foo::before_topic';
after  { } call 'Foo::after_topic';
around { $_->proceed } call 'Foo::around_topic';

$_ = 'test2';
is( Foo::around_topic(), 'Topic is test2', 'around_topic hooked ok' );
is( Foo::before_topic(), 'Topic is test2', 'before_topic hooked ok' );
is( Foo::after_topic(),  'Topic is test2', 'after_topic hooked ok' );





######################################################################
# Topic Manipulation

SCOPE: {
	package Bar;

	sub around_topic {
		$_ += 10;
		return "Topic is $_";
	}

	sub before_topic {
		$_ += 100;
		return "Topic is $_";
	}

	sub after_topic {
		$_ += 1000;
		return "Topic is $_";
	}
}

# Do the functions initiall work
$_ = 1;
is( Bar::around_topic(), 'Topic is 11',   'around_topic unhooked ok' );
is( Bar::before_topic(), 'Topic is 111',  'before_topic unhooked ok' );
is( Bar::after_topic(),  'Topic is 1111', 'after_topic unhooked ok'  );

# Set up some null aspects over the topic functions
before { } call 'Bar::before_topic';
after  { } call 'Bar::after_topic';
around { $_->proceed } call 'Bar::around_topic';

$_ = 2;
is( Bar::around_topic(), 'Topic is 12',   'around_topic hooked ok' );
is( Bar::before_topic(), 'Topic is 112',  'before_topic hooked ok' );
is( Bar::after_topic(),  'Topic is 1112', 'after_topic hooked ok'  );
