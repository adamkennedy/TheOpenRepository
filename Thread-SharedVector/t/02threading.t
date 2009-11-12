use strict;
use warnings;

sub _approx_eq { $_[0]+1.e-9 > $_[1] && $_[0]-1.e-9 < $_[1] }

use Test::More tests => 13;
use Thread::SharedVector;
use threads;
pass();

my $sv = Thread::SharedVector->new("double");
isa_ok($sv, 'Thread::SharedVector');
my $id = $sv->GetId();
is($sv->GetSize(), 0, "New SharedVector has size zero");
$sv->Push(12.3);
is($sv->GetSize(), 1, "SharedVector has size one");
ok(_approx_eq($sv->Get(0), 12.3), "Data in SV");

my $thr = threads->new(sub {
  my $sv2 = Thread::SharedVector->new($id);
  is($sv2->GetSize(), 1, "Cloned SharedVector has size one");
  ok(_approx_eq($sv->Get(0), 12.3), "Data in SV in subthread");
  $sv2->Push(2.);
  pass("Survived push");
  is($sv2->GetSize(), 2, "Modified SharedVector has size two");
  ok(_approx_eq($sv->Get(1), 2.), "Data in SV in subthread");
});
#$thr->join();
sleep 2;

is($sv->GetSize(), 2, "Size propagated back to main thread");
ok(_approx_eq($sv->Get(0), 12.3), "Old data propagated back to main thread");
ok(_approx_eq($sv->Get(1), 2.), "Data propagated back to main thread");

$thr->join();

pass();

