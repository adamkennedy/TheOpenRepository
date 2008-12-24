#!/usr/bin/perl

# Main testing for Module::Manifest

use strict;
BEGIN {
  $^W = 1;
}

use Test::More tests => 10;
use Module::Manifest ();

# Load our own MANIFEST/MANIFEST.SKIP files
{
  my $manifest = Module::Manifest->new('MANIFEST', 'MANIFEST.SKIP');
  isa_ok($manifest, 'Module::Manifest');

  is($manifest->file, 'MANIFEST', 'Manifest is set properly');
  is($manifest->skipfile, 'MANIFEST.SKIP', 'Skip file is set properly');

  my $exists = 0;
  foreach my $file ($manifest->files) {
    if ($file eq 'MANIFEST') {
      $exists = 1;
      last;
    }
  }
  ok($exists, 'MANIFEST exists in parsed input');
}

# Test that it can parse a skip file appropriately
{
  my $manifest = Module::Manifest->new;

  $manifest->parse(skip => [
    '\B\.svn\b',
    '^Build$',
    '\bMakefile$',
  ]);
  ok($manifest->skipped('Makefile'), 'Skips Makefile');
  ok($manifest->skipped('/var/cpan/Makefile'), 'Skips full path Makefile');
  ok($manifest->skipped('Build'), 'Skips standard Build script');
  ok($manifest->skipped('/var/cpan/.svn/config'), 'Skips .svn control dir');
  ok(!$manifest->skipped('Makefile.PL'), 'Does not skip Makefile.PL');
  ok(!$manifest->skipped('/var/cpan/Build'), 'Does not skip full path Build');
}
