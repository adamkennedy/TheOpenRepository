#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id$

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'Math::Random::ISAAC',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/Math/Random/ISAAC.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  requires => {
    'perl'              => 5.006,

    # The tests are based on Test::More
    'Test::More'        => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
  },
  recommends => {
    # The XS version of this module
    'Math::Random::ISAAC::XS'       => 0,
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Math-Random-ISAAC-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Math-Random-ISAAC',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Math-Random-ISAAC',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Random-ISAAC',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
