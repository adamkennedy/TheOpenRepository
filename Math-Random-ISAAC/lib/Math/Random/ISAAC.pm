# Math::Random::ISAAC
#  An interface that automagically selects the XS or Pure Perl
#  port of the ISAAC Pseudo-Random Number Generator
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

package Math::Random::ISAAC;

use version; our $VERSION = qv('0.1');

# Try to load the XS version first
eval {
  require Math::Random::ISAAC::XS;
};

# Fall back on the Perl version
if ($@) {
  $DRIVER = 'PP';
  require Math::Random::ISAAC::PP;
}
else {
  $DRIVER = 'XS';
}

# Wrappers around the actual methods
sub new {
  my $class = shift;
  # The rest of the parameters are seed data
  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
  };

  if ($DRIVER eq 'XS') {
    $self->{backend} = Math::Random::ISAAC::XS->new(@_);
  }
  else {
    $self->{backend} = Math::Random::ISAAC::PP->new(@_);
  }

  bless($self, __PACKAGE__);
  return $self;
}

sub rand {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{backend}->rand();
}

sub randInt {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{backend}->randInt();
}

1;
