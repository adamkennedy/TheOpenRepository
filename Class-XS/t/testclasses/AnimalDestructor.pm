package AnimalDestructor;
use strict;
use warnings;
use Class::XS
  public => {
    get_set=> [qw(
      length mass name
    )],
  },
  destructors => [
    sub {Test::More::ok(1, "Destructor one was called!");},
    sub {
      my $self = shift;
      Test::More::ok(1, "Destructor two was called!");
      Test::More::ok((ref($self) eq 'AnimalDestructor'), "obj passed in as first arg");
    },
  ];

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
