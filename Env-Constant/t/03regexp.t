use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
  %ENV = (foo => 'bar', 'BUZ_BUZ' => 'baz', frob => 'nicate');
}

use Env::Constant qr/^f/;

is(ENV_foo, 'bar', 'foo matches');
is(ENV_frob, 'nicate', 'frob matches');
ok(!eval "ENV_BUZ_BUZ", 'BUZ_BUZ not exported');


