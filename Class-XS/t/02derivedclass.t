use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Class::XS') };

package Animal;
use Class::XS
  public_attributes => [qw(
      length mass name
  )];

package Dog;
use Class::XS
  derive => [qw(
    Animal
  )];

package main;
my $dog = Dog->new();
isa_ok($dog, 'Dog');
isa_ok($dog, 'Animal');

ok(!defined($dog->get_length()), 'attributes initialized as undef');
is($dog->set_length(150), 150, 'setter returns new value');
is($dog->get_length(), 150, 'getter returns new value');

ok(!defined($dog->get_mass()), 'other attribute also initialized as undef');
is($dog->set_mass(60), 60, 'other setter returns new value');
is($dog->get_mass(), 60, 'other getter returns new value');




