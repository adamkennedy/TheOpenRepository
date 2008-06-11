package AnimalDestructorClash;
use strict;
use warnings;

sub DESTROY {
  print "Hi, I'll produce a clash.";
}

use Class::XS
  public => {
    attributes => [qw(
      length
    )],
  };

1;
