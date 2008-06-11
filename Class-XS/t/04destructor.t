use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('Class::XS') };

use lib 't/testclasses';
use lib 'testclasses';

use AnimalDestructor;

{
  my $animal = AnimalDestructor->new();
  isa_ok($animal, 'AnimalDestructor');

  ok(!defined($animal->get_length()), 'attributes initialized as undef');
  is($animal->set_length(150), 150, 'setter returns new value');
  is($animal->get_length(), 150, 'getter returns new value');

  ok(!defined($animal->get_mass()), 'other attribute also initialized as undef');
  is($animal->set_mass(60), 60, 'other setter returns new value');
  is($animal->get_mass(), 60, 'other getter returns new value');

  is($animal->get_length_pp(), 150, 'additional pure-Perl method can call getter');
  is($animal->set_length_pp(120), 120, 'additional pure-Perl method can call setter');
}

{
  my $animal2 = AnimalDestructor->new();
  ok(!defined($animal2->get_length()), 'a second object does not retain the attributes of the first...');
  is($animal2->set_length(110), 110, 'a second object has working setters');
}

eval <<'HERE';
use AnimalDestructorClash;
HERE
ok($@, "using Class::XS from a class which already has DESTROY fails");

