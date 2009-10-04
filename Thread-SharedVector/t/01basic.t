use strict;
use warnings;

use Test::More tests => 1 + 5 + 10;
use Thread::SharedVector;
pass();

my @svs;
my %ids;
foreach my $i (0 .. 4) {
  my $sv = Thread::SharedVector->new("double");
  push @svs, $sv;
  ok(!exists($ids{$sv->GetId()}), "used new id");
  $ids{$sv->GetId()}++;
}
@svs = ();

isa_ok(Thread::SharedVector->new("int"), 'Thread::SharedVector');


SCOPE: {
  my $sv = Thread::SharedVector->new("double");
  is($sv->GetSize(), 0, 'empty to start with');
  is($sv->Push(2), 1, "pushing a 2"); # this isn't a bool 1 but mimicking Perl's push
  is($sv->GetSize(), 1, 'one elem after first push');
  is($sv->Push(1), 2, "pushing a 1");
  is($sv->GetSize(), 2, 'two elems after second push');
  is($sv->Get(0), 2, "first elem is 2");
  is($sv->Get(1), 1, "second elem is 1");
  is($sv->Get(-1), 1, "last elem is 1");
  is($sv->Get(-2), 2, "second to last elem is 2");
}

__END__

warn "starting...";
sleep 5;
while (1) {
  my $sv = Thread::SharedVector->new("double");
  $sv->Push(2) for 1..100000;
}

