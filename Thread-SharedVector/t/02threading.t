use strict;
use warnings;
use constant DEBUG => 1;

sub _approx_eq { $_[0]+1.e-9 > $_[1] && $_[0]-1.e-9 < $_[1] }

use Test::More tests => 12;
use Thread::SharedVector;
use threads;
pass();

sub _thread_sub {
  my $sv2 = Thread::SharedVector->new(shift @_);
  is($sv2->GetSize(), 1, "Cloned SharedVector has size one");
  ok(_approx_eq($sv2->Get(0), 12.3), "Data in SV in subthread");
  $sv2->Push(2.);
  pass("Survived push");
  is($sv2->GetSize(), 2, "Modified SharedVector has size two");
  print "#exiting subthread\n" if DEBUG;
}

sub make_thread {
  my $id = shift;
  print "#starting subthread\n" if DEBUG;
  my $thr = threads->new(\&_thread_sub, $id);
  sleep 2;
  print "#joining subthread\n" if DEBUG;
  $thr->join();
  print "#subthread joined\n" if DEBUG;
  pass();
}

my $sv = Thread::SharedVector->new("double");
isa_ok($sv, 'Thread::SharedVector');
my $id = $sv->GetId();
is($sv->GetSize(), 0, "New SharedVector has size zero");
$sv->Push(12.3);
is($sv->GetSize(), 1, "SharedVector has size one");
ok(_approx_eq($sv->Get(0), 12.3), "Data in SV");

make_thread($id);

is($sv->GetSize(), 2, "Size propagated back to main thread");
ok(_approx_eq($sv->Get(0), 12.3), "Old data propagated back to main thread");
ok(_approx_eq($sv->Get(1), 2.), "Data propagated back to main thread");


