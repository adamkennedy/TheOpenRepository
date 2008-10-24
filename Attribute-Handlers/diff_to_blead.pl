#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $diff = 'diff';

my $path = 'lib/Attribute';
# local => blead
my %files = (
  "$path/Handlers.pm" => "$path/Handlers.pm",
  "README" => "$path/Handlers/README",
  "Changes" => "$path/Handlers/Changes",

  "t/constants.t" => "$path/Handlers/t/constants.t",
  "t/data_convert.t" => "$path/Handlers/t/data_convert.t",
  "t/linerep.t" => "$path/Handlers/t/linerep.t",
  "t/multi.t" => "$path/Handlers/t/multi.t",

  (map {("demo/$_" => "$path/Handlers/demo/$_")} qw(
    demo2.pl
    demo3.pl
    demo4.pl
    demo_call.pl
    demo_chain.pl
    demo_cycle.pl
    demo_hashdir.pl
    demo_phases.pl
    demo.pl
    Demo.pm
    demo_range.pl
    demo_rawdata.pl
    Descriptions.pm
    MyClass.pm
  )),
);

sub usage {
  print <<HERE;
Usage: $0 -b /path/to/blead/checkout
Does a diff of various files from here to blead
-r reverses the diff
HERE
  exit(1);
}

my $bleadpath;
my $reverse = 0;
GetOptions(
  'b|blead=s' => \$bleadpath,
  'h|help' => \&usage,
  'r|reverse' => \$reverse,
);

usage() if not defined $bleadpath or not -d $bleadpath;

foreach my $local_file (keys %files) {
  my $blead_file = "$bleadpath/" . $files{$local_file};
  if ($reverse) {
    system($diff, '-u', $blead_file, $local_file);
  }
  else {
    system($diff, '-u', $local_file, $blead_file);
  }
}
