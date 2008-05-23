use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Class::XS') };

package Animal;
use Class::XS
  public_attributes => [qw(
      length mass name
  )];

sub other_method_reading {
  my $self = shift;
  return $self->get_length();
}

sub other_method_writing {
  my $self = shift;
  my $value = shift;

  $self->set_length($value);
  return $self->get_length();
}

package main;
my $animal = Animal->new();
isa_ok($animal, 'Animal');

ok(!defined($animal->get_length()), 'attributes initialized as undef');
is($animal->set_length(150), 150, 'setter returns new value');
is($animal->get_length(), 150, 'getter returns new value');

ok(!defined($animal->get_mass()), 'other attribute also initialized as undef');
is($animal->set_mass(60), 60, 'other setter returns new value');
is($animal->get_mass(), 60, 'other getter returns new value');

is($animal->other_method_reading(), 150, 'additional pure-Perl method can call getter');
is($animal->other_method_writing(120), 120, 'additional pure-Perl method can call setter');

my $animal2 = Animal->new();
ok(!defined($animal2->get_length()), 'a second object does not retain the attributes of the first...');
is($animal2->set_length(110), 110, 'a second object has working setters');
is($animal->get_length(), 120, 'first object not affected by second object');

