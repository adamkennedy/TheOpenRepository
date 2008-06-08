package Animal::FourLegged;
use strict;
use warnings;
use Class::XS
  public => {
    attributes => [qw(
      leg_length
    )]
  };

1;
