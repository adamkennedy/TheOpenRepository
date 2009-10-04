use strict;
use warnings;

use Test::More tests => 1;
use Thread::SharedVector;
pass();

my @svs;
foreach my $i (0 .. 10) {
  my $sv = Thread::SharedVector->new("double");
  push @svs, $sv;
  print $sv->GetId(), "\n";
}

foreach my $i (20 .. 30) {
  my $sv = Thread::SharedVector->new("double");
  print $sv->GetId(), " ", $sv->GetSize(), "\n";
}
