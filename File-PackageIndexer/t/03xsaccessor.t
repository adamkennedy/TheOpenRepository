use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('File::PackageIndexer') };

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'empty',
    code => <<'HERE',
HERE
    'cmp' => undef,
  },
  {
    name => 'simple',
    code => <<'HERE',
sub foo {}
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1} },
    },
  },
  {
    name => 'empty xsa',
    code => <<'HERE',
sub foo {}
use Class::XSAccessor;
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1} },
    },
  },
  {
    name => 'simple xsa constructor',
    code => <<'HERE',
sub foo {}
use Class::XSAccessor
  constructor => 'bar';
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1, bar => 1} },
    },
  },
  {
    name => 'simple xsa getter',
    code => <<'HERE',
use Class::XSAccessor
  getters => { bar => 'bar' };

sub foo {}
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1, bar => 1} },
    },
  },
);

foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  is_deeply($index, $ref, "equivalence test: $name");
}

