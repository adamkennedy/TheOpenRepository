use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
  %ENV = (foo => 'bar');
}

use Env::Constant;
pass('run time');
is(ENV_foo(), 'bar', 'matches');


