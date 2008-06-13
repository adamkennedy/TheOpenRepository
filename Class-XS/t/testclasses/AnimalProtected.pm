package AnimalProtected;
use strict;
use warnings;
use Class::XS
  public => {
    get_set => [qw(
      mass
    )]
  },
  private => {
    get_set => [qw(
      length
    )]
  },
  protected => {
    get_set => [qw(
      name
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
