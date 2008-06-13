package Animal::FourLegged;
use strict;
use warnings;
use Class::XS
  public => {
    get_set => [qw(
      leg_length
    )]
  };

1;
