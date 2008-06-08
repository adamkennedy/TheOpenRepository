use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Class::XS') };

package Animal;
use Class::XS
  public => {
    attributes => [qw(
      length mass name
    )],
  };

BEGIN {
  eval << 'HERE';
use Class::XS
  public => {
    attributes => [qw(
      foo bar
    )],
  };
HERE
  Test::More::ok($@, "using Class::XS from the same package twice fails miserably as it should");
}

