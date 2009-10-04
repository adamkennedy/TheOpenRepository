#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id$

use strict;
use warnings;

use lib 'inc';
use My::Builder;

use Env '@PATH';

my $builder = My::Builder->new(
  module_name           => 'Alien::Libjio',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <jawnsy@cpan.org>',
  dist_version_from     => 'lib/Alien/Libjio.pm',
  dynamic_config        => 1,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  requires => {
    'perl'              => 5.006,
  },
  build_requires => {
    # User tests for good functionality
    'Test::More'              => 0.62,
    'Test::NoWarnings'        => 0.084,

    # For the C compiling process
    'ExtUtils::CBuilder'      => 0,
  },
  recommends => {
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Alien-Libjio-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Alien-Libjio',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Alien-Libjio',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Libjio',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

# Use Alien::Libjio to see if it's already installed
use lib 'lib';
use Alien::Libjio;

my $jio = Alien::Libjio->new();

unless ($jio->installed) {
  # Ask the user if they'd like to install this; if not, then exit
  $builder->y_n('libjio was not found on your system. Install it now?', 'y')
    or exit;

  $builder->notes(build_libjio => 1);

  # Ask the user what 'make' program to invoke
  my $make;
  if (exists($ENV{MAKE}) && length($ENV{MAKE})) {
    $make = $ENV{MAKE};
  }
  else {
    use Config '%Config';
    $make = $Config{make};

    # Probe for GNU Make (useful on BSD/Unix variants)
    if ($make eq 'make' && grep { -x $_ . '/gmake' } @PATH) {
      $make = 'gmake';
      if ($^O =~ /bsd$/) {
        print {*STDERR} "warning: your system is a BSD variant but " .
          "gmake wasn't found.\n";
      }
    }
  }
  $make = $builder->prompt('What is your system "make" command?', $make);

  $builder->notes(make => $make);

  # Figure out if we should do a full install
  my $extra = $builder->y_n('libjio includes other files including Python ' .
    'bindings. Install them too?', 'n');
  $builder->notes(extra => $extra);
}

$builder->create_build_script();
