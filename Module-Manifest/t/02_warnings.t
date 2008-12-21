#!/usr/bin/perl -T

# t/02_warnings.t
#  Tests that Module::Manifest emits appropriate warnings
#
# $Id: 01meta.t 4 2008-12-19 03:43:56Z frequency $

use strict;
BEGIN {
	$^W = 1;
}

use Test::More tests => 1;
use Module::Manifest ();

# Can't import, because the later redefinition will cause a warning
eval 'use Test::Warn ()';

if ($@) {
  plan skip_all => 'Test::Warn required to test warnings';
}

# eval'ing use will not bring in the prototype; we have to redefine here
sub warning_like (&$;$) { Test::Warn::warnings_like(@_) };

# Test that duplicate items elicit a warning
warning_like {
	my $manifest = Module::Manifest->new;
	$manifest->parse(manifest => [
		'.svn',
		'.svn/config',
		'Makefile.PL',
		'Makefile.PL',
	]);
} qr/Duplicate file/, 'Duplicate insertions cause warning';
