use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('File::PackageIndexer') };
use Data::Dumper;

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'simple xsa',
    code => <<'HERE',
package Foo;
require Class::XSAccessor;
Class::XSAccessor->import(constructor => 'new');
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {new => 1}, isa => [], },
    },
  },
  {
    name => 'simple base',
    code => <<'HERE',
package Foo;
require base;
base->import('Bar');
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar'], },
    },
  },
  {
    name => 'mixed xsa and base',
    code => <<'HERE',
package Foo;
require Class::XSAccessor;
require base;
Class::XSAccessor->import(
  constructor => 'new',
  getters => { ggg => 'ggg' },
);
base->import(('Bar', qw(Baz)));
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {new => 1, ggg => 1}, isa => ['Bar', 'Baz'], },
    },
  },
);

foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  is_deeply($index, $ref, "equivalence test: $name") or warn Dumper $index;
}

