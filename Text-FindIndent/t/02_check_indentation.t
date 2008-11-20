#!/usr/bin/perl
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec;
use Text::FindIndent;

my %tests = (
  t1 => [qw(
    tabs1_1.txt
  )],
  s2 => [qw(
    spaces2_1.txt
  )],
  s4 => [qw(
    spaces4_1.txt
  )],
  u => [qw(
    unknown_1.txt
  )],
  m4 => [qw(
    mixed4_1.txt
  )],
    #mixed4_2.txt
);

my $no_tests = 0;
foreach (map {scalar @$_} values %tests) {
  $no_tests += $_ * 3;
}
plan tests => $no_tests;


chdir('t') if -d 't';


foreach my $exp_result (keys %tests) {
  my $testfiles = $tests{$exp_result};
  foreach my $file (@$testfiles) {
    my $testfile = File::Spec->catfile("data", $file);

    my $text = slurp($testfile);
    ok(defined $text, "slurped file '$testfile'");
    my $result = Text::FindIndent->parse($text);
    ok(defined $result, "Text::FindIndent->parse(text) returns something");
    is($result, $exp_result, "Text::FindIndent->parse(text) returns correct result");

  }
}

sub slurp {
  my $file = shift;
  open FH, "<$file" or die $!;
  local $/ = undef;
  my $text = <FH>;
  close FH;
  return $text;
}

