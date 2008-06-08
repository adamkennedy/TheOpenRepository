package Animal;
use strict;
use warnings;
use Class::XS
  public => {
    attributes => [qw(
      length mass name
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
