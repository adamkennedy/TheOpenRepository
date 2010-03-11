#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Test::UseAllModules;

all_uses_ok();
diag( "Testing Win32::Exe $Win32::Exe::VERSION" );


