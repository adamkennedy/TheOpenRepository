package AnimalPrivate;
use strict;
use warnings;
use Class::XS
  public => {
    get_set => [qw(
      mass name
    )]
  },
  private => {
    get_set => [qw(
      length
    )]
  };

sub get_length_pp {
  my $self = shift;
  return $self->get_length();
}

sub set_length_pp {
  my $self = shift;
  my $value = shift;

  $self->set_length($value);
  return $self->get_length();
}


1;
