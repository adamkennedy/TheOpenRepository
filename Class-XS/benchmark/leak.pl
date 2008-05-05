#!/usr/bin/perl
use strict;
use warnings;

package Bar;
use Class::XS
  public_attributes => [qw(attr1 attr2)];

package main;
my $t;

print "Please monitor memory usage of this process. Hit <ENTER> when ready.\n",
$t = <STDIN>;
undef $t;

my @obj;
foreach (1..10000) {
  push @obj, Bar->new();
}

print "Please note the current memory usage. It should not grow significantly until you see the next message. Hit <ENTER> when ready.\n";
$t = <STDIN>;
undef $t;

foreach (1..1000) {
  @obj = ();
  foreach (1..10000) {
    push @obj, Bar->new();
  }
}

print "Has the memory usage increased significantly? Then there may be a leak. Hit <ENTER> to quit.\n";
$t = <STDIN>;
undef $t;

