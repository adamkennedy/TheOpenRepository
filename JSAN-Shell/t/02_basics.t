#!/usr/bin/perl

# Compile testing for jsan2

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
BEGIN {
	$DB::single = 1;
}
use JSAN::Shell ();





#####################################################################
# Object creation

my $shell = JSAN::Shell->new;
isa_ok( $shell, 'JSAN::Shell' );





#####################################################################
# Config manipulation

my @config_true  = qw{ t true y yes 1 on  };
my @config_false = qw{ f false n no 0 off };
foreach ( @config_true ) {
	# ...
}
