#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB::Generator;

our $VERSION = '0.14';

my $cpandb = CPANDB::Generator->new(
	cpanmeta => 1,
	minicpan => 'F:\minicpan',
	trace    => 1,
);

$cpandb->run;

exit(0);
