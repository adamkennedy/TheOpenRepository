#!/usr/bin/perl
use Pod::Perldoc;

$package = shift @ARGV;
	my $file = Pod::Perldoc->new( args=>[ '-l' => $package ]);
	my ($filename) = 	 $file->grand_search_init( [$package ]);

warn $filename;
