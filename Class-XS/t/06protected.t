use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Class::XS') };

use lib 't/testclasses';
use lib 'testclasses';

use AnimalProtected;
use Animal::DogProtected;

my $animal = AnimalProtected->new();
isa_ok($animal, 'AnimalProtected');

ok(!defined($animal->get_mass()), 'public attribute also initialized as undef');
is($animal->set_mass(60), 60, 'public setter returns new value');
is($animal->get_mass(), 60, 'public getter returns new value');

is($animal->set_length_pp(120), 120, 'additional pure-Perl method can call setter');
is($animal->get_length_pp(), 120, 'additional pure-Perl method can call getter');

eval '$animal->get_length()';
ok($@, 'calling private getter fails');
eval '$animal->set_length(50)';
ok($@, 'calling private setter fails');

eval '$animal->get_name()';
ok($@, 'calling protected getter fails');
eval '$animal->set_name("foo")';
ok($@, 'calling protected setter fails');

my $dog = Animal::DogProtected->new();
isa_ok($dog, 'Animal::DogProtected');
isa_ok($dog, 'AnimalProtected');

ok(!defined($dog->get_mass()), 'public attribute also initialized as undef');
is($dog->set_mass(20), 20, 'public setter returns new value');
is($dog->get_mass(), 20, 'public getter returns new value');
is($animal->get_mass(), 60, 'public getter on old object returns old value');

is($dog->set_barking_sound("barf"), "barf", 'public subclass setter');
is($dog->get_barking_sound(), "barf", 'public subclass getter');


eval '$dog->get_length()';
ok($@, 'calling private getter fails');
eval '$dog->set_length(50)';
ok($@, 'calling private setter fails');

eval '$dog->get_name()';
ok($@, 'calling protected getter fails');
eval '$dog->set_name("foo")';
ok($@, 'calling protected setter fails');

is($dog->set_name_pp("peter"), "peter", "subclass can access protected attributes");
is($dog->get_name_pp(), "peter", "subclass can access protected attributes");

