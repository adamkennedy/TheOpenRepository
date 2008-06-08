use strict;
use warnings;

use Test::More tests => 35;
BEGIN { use_ok('Class::XS') };

#
#   Animal    KnowsMeaningOfLifeMixin    FourLegged
#     ^        ^                           ^
#   Canine--- / --------------------------/
#     ^     /                           /
#     |   /                           /
#     | /                           /
#     Dog --------------------------
#
#  (both Dog and Canine are FourLegged. You wouldn't do that in reality, but this is worst-case testing...)
#


use lib 't/testclasses';
use lib 'testclasses';

use Animal::Dog;

my $dog = Animal::Dog->new();
isa_ok($dog, 'Animal::Dog');
isa_ok($dog, 'Animal::Canine');
isa_ok($dog, 'Animal');
isa_ok($dog, 'KnowsMeaningOfLifeMixin');
isa_ok($dog, 'Animal::FourLegged');

# Test getters/setters from superclass
ok(!defined($dog->get_length()), 'attributes initialized as undef');
is($dog->set_length(150), 150, 'setter returns new value');
is($dog->get_length(), 150, 'getter returns new value');

ok(!defined($dog->get_mass()), 'other attribute also initialized as undef');
is($dog->set_mass(60), 60, 'other setter returns new value');
is($dog->get_mass(), 60, 'other getter returns new value');

# Test extra methods from superclass
is($dog->get_length_pp(), 150, 'additional pure-Perl method can call getter');
is($dog->set_length_pp(120), 120, 'additional pure-Perl method can call setter');

# Test Canine's methods
ok(!defined($dog->get_gender()), 'intermediate class attributes initialized as undef');
is($dog->set_gender("m"), "m", 'initialized class setter returns new value');
is($dog->get_gender(), "m", 'intermediate class getter returns new value');

# Test Animal::Dog's own methods
ok(!defined($dog->get_barking_sound()), 'child class attributes initialized as undef');
is($dog->set_barking_sound("woof"), "woof", 'child class setter returns new value');
is($dog->get_barking_sound(), "woof", 'child class getter returns new value');

# Test Animal::Dog's own extra methods
is($dog->get_barking_sound_pp(), "woof", 'child class additional pure-Perl method can call getter');
is($dog->set_barking_sound_pp("WOOF"), "WOOF", 'child class additional pure-Perl method can call setter');

# test MeaningOfLife PP mixin
ok($dog->can("meaning_of_life"), "pp mixin works");
is($dog->meaning_of_life(), 42, "pp mixin returns right value");

# test FourLegged mixin
ok(!defined($dog->get_leg_length()), 'mixin class attributes initialized as undef');
is($dog->set_leg_length(12), 12, 'mixin class setter returns new value');
is($dog->get_leg_length(), 12, 'mixin class getter returns new value');

# Test whether a second object of the same class disturbs the first
my $dog2 = Animal::Dog->new();
isa_ok($dog2, 'Animal::Dog');
isa_ok($dog2, 'Animal::Canine');
isa_ok($dog2, 'Animal');
isa_ok($dog2, 'KnowsMeaningOfLifeMixin');
isa_ok($dog2, 'Animal::FourLegged');
ok(!defined($dog2->get_length()), 'a second object does not retain the attributes of the first...');
is($dog2->set_length(110), 110, 'a second object has working setters');
is($dog->get_length(), 120, 'first object not affected by second object');


