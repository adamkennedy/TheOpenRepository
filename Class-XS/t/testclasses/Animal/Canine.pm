package Animal::Canine;
use strict;
use warnings;
use Class::XS
  derive => [qw(
    Animal
    Animal::FourLegged
  )],
  public => {
    attributes => [qw(
    gender
    )]
  };

1;
