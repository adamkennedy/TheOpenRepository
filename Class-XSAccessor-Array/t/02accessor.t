use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor::Array
  accessors => { bar => 0 },
  getters   => { get_foo => 1 },
  setters   => { set_foo => 1 };

sub new {
  my $class = shift;
  bless [ 'baz' ], $class;
}

package main;

use Test::More tests => 6;

my $obj = Class::XSAccessor::Test->new();

ok ($obj->can('bar'));
is ($obj->set_foo('bar'), 'bar');
is ($obj->get_foo(), 'bar');
is ($obj->bar(), 'baz');
is ($obj->bar('quux'), 'quux');
is ($obj->bar(), 'quux');

