use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
  %ENV = (foo => 'bar', 'BUZ_BUZ' => 'baz');
}

package MyTestPackage;
use Env::Constant;
Test::More::pass('run time');
Test::More::is(ENV_foo, 'bar', 'foo matches');
Test::More::is(ENV_BUZ_BUZ, 'baz', 'BUZ_BUZ matches');

package main;
is(MyTestPackage::ENV_foo, 'bar', 'foo matches from other package');
ok(!eval "ENV_foo", 'foo not exported to main');


