#!/usr/bin/perl -T

# t/01_strict.t
#  Check that all modules use the 'strict' and 'warnings' pragmas
#
# $Id$

use strict;
BEGIN {
	$^W = 1;
}

use Test::More;

eval 'use Test::Strict 0.06';

if ($@) {
  plan skip_all => 'Test::Strict 0.06 required to force strict and warnings';
}

{
  # If Test::Strict is not loaded, Perl warns that we used these only once
  no warnings 'once';

  # Test options for all_perl_files_ok()
  $Test::Strict::TEST_SYNTAX   = 0; # Tested with use_ok anyway
  $Test::Strict::TEST_STRICT   = 1;
  # The warnings pragma was introduced in Perl 5.6
  $Test::Strict::TEST_WARNINGS = ($] >= 5.006) ? 1 : 0;
}

Test::Strict::all_perl_files_ok();
