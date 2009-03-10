#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use DBM::Deep;
use File::Path ();
use File::Spec;
use Digest::MD5 'md5_base64';

sub usage {
  warn "$_[0]\n" if defined $_[0];
  warn <<HERE;
Usage: $0 [--verbose] DBFILE
Usage: $0 DBFILE DistOrModuleRegex
Usage: $0 --html DBFILE
HERE
  exit(1);
}

my ($verbose, $toHTML);
GetOptions(
  'h|help' => \&usage,
  'v|verbose' => \$verbose,
  'h|html' => \$toHTML,
);

my $datafile = shift @ARGV;
usage("File does not exist") if not defined $datafile or not -f $datafile;
my $regex = shift @ARGV;
$regex = qr/$regex/ if defined $regex;

my $db = DBM::Deep->new($datafile);
if ($toHTML) {
  to_html($db);
}
elsif (defined $regex) {
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

sub to_html {
  my $db = shift;

  my $dir = 'dld-html';
  die "Directory '$dir' exists!" if -d $dir;

  File::Path::mkpath("dld-html");

  open my $ifh, '>', File::Spec->catdir($dir, "index.html") or die $!;
  print $ifh <<'HERE';
<html>
<head><title>dualLivedDiff</title></head>
<body>
<table cellspacing="2" cellpadding="3" border="0">
<tr>
<th>Distname</th><th>Status</th><th>Diff</th><th>Length</th><th>Date of Diff</th><th>File Mapping</th>
</tr>
HERE

  foreach my $distname (
        map {$_->[0]}
        sort {$a->[1] cmp $b->[1]}
        map {my $n = $_; s/^[^\/]*\///;[$n, $_]}
        keys %$db
  ) {
    my $dist = $db->{$distname};
    my $status = $dist->{status};
    my $diff = $dist->{diff};
    my $date = localtime($dist->{date});

    my $diffLink = '-';
    my $bgcolor = '#00FF00';
    my $filename = md5_base64($distname) . ".txt";
    $filename =~ s/[\/:]//g;
    if ($status !~ /^ok/i) {
      open my $fh, '>', File::Spec->catfile($dir, $filename) or die $!;
      print $fh $diff;
      close $fh;
      $bgcolor = '#FF0000';
      $diffLink = "<a href=\"$filename\">Diff</a>";
    }

    my $configFilename = "config-$filename";
    $configFilename =~ s/\.[^.]*$/\.cfg/;
    my $configLink = "<a href=\"$configFilename\">cfg</a>";
    open my $cfh, '>', File::Spec->catfile($dir, $configFilename) or die $!;
    print $cfh $dist->{config};
    close $cfh;

    my $diffLen = defined($diff) ? length($diff) : 0;
    print $ifh <<HERE;
<tr bgcolor="$bgcolor">
<td>$distname</td><td>$status</td><td>$diffLink</td><td align="right">$diffLen</td><td>$date</td><td>$configLink</td>
</tr>
HERE

  }
  
  print $ifh <<'HERE';
</table>
</body>
</html>
HERE
  close $ifh;
}


