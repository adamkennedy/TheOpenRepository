#!/usr/bin/perl -T

# t/02_exceptions.t
#  Tests that Module::Manifest throws appropriate exceptions
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More;
use Module::Manifest ();

# Set up Test::Exception if it's available
eval {
  require Test::Exception;
  Test::Exception->import;
};
if ($@) {
  plan skip_all => 'Test::Exception required to test exceptions';
}

plan tests => 10;

# Fail when parse called without an array reference
throws_ok(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->parse(manifest => 'file');
  },
  qr/specified as an array reference/,
  'Enforce ARRAY ref with parse'
);

# Fail if skipped called without a filename
throws_ok(
  sub {
    my $manifest = Module::Manifest->new;
    my $skip = $manifest->skipped;
  },
  qr/must pass a filename/,
  'Enforce filename/path to $manifest->skipped call'
);

# Fail when parse called with invalid type
throws_ok(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->parse(invalid => [ 'file' ]);
  },
  qr/Available types are/,
  'Enforce type parameter to parse'
);

# Fail when calls are not object methods
throws_ok(
  sub {
    Module::Manifest->open;
  },
  qr/as an object/,
  'Static Module::Manifest->open call'
);

throws_ok(
  sub {
    Module::Manifest->parse;
  },
  qr/as an object/,
  'Static Module::Manifest->parse call'
);

throws_ok(
  sub {
    my $dir = Module::Manifest->dir;
  },
  qr/as an object/,
  'Static Module::Manifest->dir call'
);

throws_ok(
  sub {
    my $skip = Module::Manifest->skipfile;
  },
  qr/as an object/,
  'Static Module::Manifest->skipfile call'
);

throws_ok(
  sub {
    my $skip = Module::Manifest->skipped('testmask');
  },
  qr/as an object/,
  'Static Module::Manifest->skipped call'
);

throws_ok(
  sub {
    my $file = Module::Manifest->file;
  },
  qr/as an object/,
  'Static Module::Manifest->file call'
);

throws_ok(
  sub {
    my $file = Module::Manifest->files;
  },
  qr/as an object/,
  'Static Module::Manifest->files call'
);
