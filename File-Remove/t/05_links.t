#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More qw(no_plan); # tests => 3;
BEGIN {
	use_ok('File::Remove' => qw(remove trash))
};

unless(eval { symlink("",""); 1 }) {
  diag("system cannot do symlinks");
  exit 0;
}

# Set up the tests

my $testdir = "linktest";
if(-d $testdir) {
  BAIL_OUT("Directory '$testdir' exists - please remove it manually");
}
unless(mkdir($testdir, 0777)) {
  BAIL_OUT("Cannot create test directory '$testdir': $!");
}
my %links = (
   l_ex => '.',
   l_ex_a => '/',
   l_nex => 'does_not_exist'
);
my $errs = 0;
foreach my $link (keys %links) {
  unless(symlink($links{$link}, "$testdir/$link")) {
    diag("Cannot create symlink $link -> $links{$link}: $!");
    $errs++;
  }
}
if($errs) {
  BAIL_OUT("Could not create test links");
}

ok( remove(\1, map { "$testdir/$_" } keys %links), "remove \\1: all links" );

my @entries;

ok(opendir(DIR, $testdir));
foreach(readdir(DIR)) {
  next if(/^\.\.?$/);
  push(@entries, $_);
}
ok(closedir(DIR));

ok(@entries == 0, "no links remained in directory; found @entries");

ok( remove(\1, $testdir), "remove \\1: $testdir" );

ok( !-e $testdir,         "!-e: $testdir" );

1;
