#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use File::Find::Rule          ();
use File::Find::Rule::NoIndex ();

use constant FFR => 'File::Find::Rule';





#####################################################################
# Create the object

my $rule = File::Find::Rule->no_index(
	directory => [ 'inc' ],
);
isa_ok( $rule, 'File::Find::Rule' );

# Search for files
my @files = $rule->in( curdir() );

1;
