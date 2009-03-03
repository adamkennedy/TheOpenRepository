#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $diff = 'diff';

my $path = 'ext/Attribute-Handlers';
# local => blead
my %files = (
  "lib/Attribute/Handlers.pm" => "$path/lib/Attribute/Handlers.pm",
  "README" => "$path/README",
  "Changes" => "$path/Changes",

  "t/constants.t" => "$path/t/constants.t",
  "t/data_convert.t" => "$path/t/data_convert.t",
  "t/linerep.t" => "$path/t/linerep.t",
  "t/multi.t" => "$path/t/multi.t",

  (map {("demo/$_" => "$path/demo/$_")} qw(
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
  my @cmd = ($diff, '-u');
  if ($reverse) {
    push @cmd, $blead_file, $local_file;
  }
  else {
    push @cmd, $local_file, $blead_file;
  }
  my $result = `@cmd`;
  my $blead_prefix = quotemeta($reverse ? '---' : '+++');
  my $local_prefix = quotemeta($reverse ? '+++' : '---');
  $result =~ s/^($blead_prefix\s*)(\S+)/$1.fix_blead_path($2,$bleadpath)/gme;
  $result =~ s/^($local_prefix\s*)(\S+)/$1.$files{$2}/gme;
  print $result;
}

sub fix_blead_path {
  my $path = shift;
  my $bleadpath = shift;
  $path =~ s/^\Q$bleadpath\E//;
  $path =~ s/^\/+//;
  return $path;
}

