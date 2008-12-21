#!/usr/bin/perl -T

# t/01_kwalitee.t
#  Uses the CPANTS Kwalitee metrics to test the distribution
#
# $Id: 01meta.t 4 2008-12-19 03:43:56Z frequency $

use Test::More;

eval {
	require Test::Kwalitee;
	Test::Kwalitee->import();
};

if ($@) {
	plan skip_all => 'Test::Kwalitee required to test distribution Kwalitee';
}
