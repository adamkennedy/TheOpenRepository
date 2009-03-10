#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use DBM::Deep;

sub usage {
  warn "$_[0]\n" if defined $_[0];
  warn <<HERE;
Usage: $0 [--verbose] DBFILE [DistOrModuleRegex]
HERE
  exit(1);
}

my $verbose;
GetOptions(
  'h|help' => \&usage,
  'v|verbose' => \$verbose,
);

my $datafile = shift @ARGV;
usage("File does not exist") if not defined $datafile or not -f $datafile;
my $regex = shift @ARGV;
$regex = qr/$regex/ if defined $regex;

my $db = DBM::Deep->new($datafile);
if (defined $regex) {
  my %dists = 
    map {($_ => 1)}
    grep { /$regex/ }
    (keys %$db);
    #(keys %$db, (map {$_->{module}} values %$db));

  die "Multiple results selected: \n" . join("\n", keys %dists) . "\n"
    if keys(%dists) > 1;
  die "No results selected\n" if not keys %dists;

  my @dists = keys %dists;
  my $dist = $db->{$dists[0]};
  print $dist->{diff};
}
elsif ($verbose) {
  print Dumper $db;
}
else {
  foreach my $k (keys %$db) {
    my $s = $db->{$k}{status};
    print "$k - $s\n";
  }
}


