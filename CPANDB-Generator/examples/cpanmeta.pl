#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB::Generator;

our $VERSION = '0.15';

my $cpandb = CPANDB::Generator->new(
	cpanmeta => 1,
	minicpan => 'G:\minicpan',
	trace    => 1,
	warnings => 1,
);

$cpandb->run;

exit(0);
