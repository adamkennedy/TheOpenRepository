use strict;
use warnings;

use Test::More tests => 32;
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

SCOPE: {
  isa_ok(Thread::SharedVector->new("int"), 'Thread::SharedVector');
}


sub _approx_eq { $_[0]+1.e-9 > $_[1] && $_[0]-1.e-9 < $_[1] }
sub identical_sv {
  my $sv1 = shift;
  my $sv2 = shift;

  my $s1 = $sv1->GetSize();
  my $s2 = $sv2->GetSize();
  is($s1, $s2, 'sizes identical');

  foreach my $i (0..$s1-1) {
    is($sv1->Get($i), $sv2->Get($i), "elem $i identical");
  }
}

SCOPE: {
  my $sv = Thread::SharedVector->new("double");
  is($sv->GetSize(), 0, 'empty to start with');
  is($sv->Push(2), 1, "pushing a 2"); # this isn't a bool 1 but mimicking Perl's push
  is($sv->GetSize(), 1, 'one elem after first push');
  is($sv->Push(1.5), 2, "pushing a 1.5");
  is($sv->GetSize(), 2, 'two elems after second push');
  is($sv->Get(0), 2, "first elem is 2");
  ok(_approx_eq($sv->Get(1), 1.5), "second elem is 1.5");
  ok(_approx_eq($sv->Get(-1), 1.5), "last elem is 1.5");
  is($sv->Get(-2), 2, "second to last elem is 2");

  is($sv->Get(100), undef, "arbitrary elem is undef");
  is($sv->Get(-100), undef, "arbitrary elem from back is undef");

  my $id = $sv->GetId();

  # Test the re-fetching of the same vector
  my $copy = Thread::SharedVector->new($id);
  is($copy->GetId(), $id, "id of copy is same");

  for my $sv ($copy) {
    is($sv->GetSize(), 2, 'two elems after second push');
    is($sv->Get(0), 2, "first elem is 2");
    ok(_approx_eq($sv->Get(1), 1.5), "second elem is 1.5");
    ok(_approx_eq($sv->Get(-1), 1.5), "last elem is 1.5");
    is($sv->Get(-2), 2, "second to last elem is 2");
  }

  $sv->Push(5);
  is($copy->Get(2), 5, 'sv -> copy propagation');
  $copy->Push(8);
  is($sv->Get(3), 8, 'copy -> sv propagation');

  identical_sv($sv, $copy);
}

is(Thread::SharedVector->new("int")->GetId(), 0, "everything gc'd");

__END__

warn "starting...";
sleep 5;
while (1) {
  my $sv = Thread::SharedVector->new("double");
  $sv->Push(2) for 1..100000;
}

