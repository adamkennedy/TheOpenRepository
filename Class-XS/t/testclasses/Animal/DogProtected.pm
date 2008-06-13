package Animal::DogProtected;
use strict;
use warnings;
# class Canine is already FourLegged, but I'm including it here as an additional complication
use Class::XS
  derive => [qw(
    AnimalProtected
  )],
  public => {
    get_set => [qw(
      barking_sound
    )],
  };


sub set_name_pp {
  my $self = shift;
  $self->set_name(shift);
  return $self->get_name();
}

sub get_name_pp {
  my $self = shift;
  return $self->get_name();
}

1;
