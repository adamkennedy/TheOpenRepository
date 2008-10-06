#!/usr/bin/perl
use strict;
use warnings;
use lib qw( ./lib );

use Macropod::Parser;

my $m = Macropod::Parser->new();
$m->parse( shift @ARGV );
print $m ;

#$m->render;
