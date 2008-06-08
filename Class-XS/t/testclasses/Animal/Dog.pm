package Animal::Dog;
use strict;
use warnings;
# class Canine is already FourLegged, but I'm including it here as an additional complication
use Class::XS
  derive => [qw(
    Animal::FourLegged
    Animal::Canine
  )],
  public => {
    attributes => [qw(
      barking_sound
    )],
  };

use base 'KnowsMeaningOfLifeMixin';

sub get_barking_sound_pp {
  my $self = shift;
  return $self->get_barking_sound();
}

sub set_barking_sound_pp {
  my $self = shift;
  my $value = shift;

  $self->set_barking_sound($value);
  return $self->get_barking_sound();
}

1;
