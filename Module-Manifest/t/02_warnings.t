#!/usr/bin/perl -T

# t/02_warnings.t
#  Tests that Module::Manifest emits appropriate warnings
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More;
use Module::Manifest ();

# Set up Test::Warn appropriately, bring in 'warning_like'
eval {
  require Test::Warn;
  Test::Warn->import;
};
if ($@) {
  plan skip_all => 'Test::Warn required to test warnings';
}

plan tests => 7;

# Test that duplicate items elicit a warning
warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->parse(manifest => [
      '.svn',
      '.svn/config',
      'Makefile.PL',
      'Makefile.PL',
    ]);
  },
  qr/Duplicate file/,
  'Duplicate insertions cause warning'
);

# Warning emitted when accessors used in void context
warning_like(
  sub {
    Module::Manifest->new;
  },
  qr/discarded/,
  'Module::Manifest->new called in void context'
);

warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->dir;
  },
  qr/discarded/,
  '$manifest->dir called in void context'
);

warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->skipfile;
  },
  qr/discarded/,
  '$manifest->skipfile called in void context'
);

warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->skipped;
  },
  qr/discarded/,
  '$manifest->skipped called in void context'
);

warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->file;
  },
  qr/discarded/,
  '$manifest->file called in void context'
);

warning_like(
  sub {
    my $manifest = Module::Manifest->new;
    $manifest->files;
  },
  qr/discarded/,
  '$manifest->files called in void context'
);
