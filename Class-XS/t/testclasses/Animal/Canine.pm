package Animal::Canine;
use strict;
use warnings;
use Class::XS
  derive => [qw(
    Animal
    Animal::FourLegged
  )],
  public => {
    get_set => [qw(
    gender
    )]
  };

1;
