use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('Class::XSAccessor::Array') };

package Foo;
use Class::XSAccessor::Array
  getters => {
    get_foo => 0,
    get_bar => 1,
  };
package main;

BEGIN {pass();}

package Foo;
use Class::XSAccessor::Array
  replace => 1,
  getters => {
    get_foo => 0,
    get_bar => 1,
  };
package main;

BEGIN {pass();}

ok( Foo->can('get_foo') );
ok( Foo->can('get_bar') );

my $foo = bless  ['a','b'] => 'Foo';
ok($foo->get_foo() eq 'a');
ok($foo->get_bar() eq 'b');

package Foo;
use Class::XSAccessor::Array
  setters=> {
    set_foo => 0,
    set_bar => 1,
  };

package main;
BEGIN{pass()}

ok( Foo->can('set_foo') );
ok( Foo->can('set_bar') );

$foo->set_foo('1');
pass();
$foo->set_bar('2');
pass();

ok($foo->get_foo() eq '1');
ok($foo->get_bar() eq '2');

# Make sure scalars are copied and not stored by reference (RT 38573)
my $x = 1;
$foo->set_foo($x);
$x++;
is( $foo->get_foo(), 1, 'scalar copied properly' );

