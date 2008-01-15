#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import( catdir( curdir(), 't', 'modules' ) );
}

use Test::More tests => 1;
use Scalar::Util 'refaddr';

use Class::Autouse;
Class::Autouse->autouse('baseB');

ok( baseB->isa('baseA'), 'isa() triggers autouse' );
