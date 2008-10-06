#!/usr/bin/perl
use PPI;
use PPI::Dumper;

my $p = PPI::Document->new( shift @ARGV );
print PPI::Dumper->new( $p )->print;
