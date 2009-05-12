#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;
use Config;

use Module::Build;

my @flags;

# Determine what the 32bit unsigned type is. Based on the result, we can
# pass two flags to the C code which will affect their behaviour.
#
# USE_PORTABLE will determine whether we try to make our bit operations
# portable by ANDing them with 0xffffffff. This cuts off higher bits,
# so that our result is good.
#
# USE_INT will determine whether to use the 'int' type compared to 'long'.
# While 'long' is guaranteed to be 32 bits or larger, on some 64-bit systems,
# int is 32 bits and long is 64 bits. On these systems we force use of int.
if ($Config{intsize} == 4) {
  # Excellent, we've got a 32-bit type. It probably doesn't matter whether we
  # use int or long here, if they are the same size. However, they would be
  # just as fast anyway, I think.
  push(@flags, '-DUSE_INT');
}
else {
  # Use the 'portable' version and hope for the best. It doesn't seem to work
  # very well right now, hopefully it's fixed for fully-64bit architectures
  # later.
  push(@flags, '-DUSE_PORTABLE');
}

# Note that even though they are currently presented that way, this does not
# necessarily mean that we must either USE_INT or USE_PORTABLE. There may be
# real cases where we don't want to USE_INT (and instead use long's, if they
# are somehow faster than ints) but are absolutely sure they are only 32bits.
# In that case we wouldn't need to USE_PORTABLE either.

my $builder = Module::Build->new(
  module_name           => 'Math::Random::ISAAC::XS',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/Math/Random/ISAAC/XS.pm',
  dynamic_config        => 1,
  create_readme         => 1,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  # Location of our special C and XS source files
  c_source => 'src',
  xs_files => {
    'src/ISAAC.xs' => 'lib/Math/Random/ISAAC/XS.xs',
  },

  extra_compiler_flags => join(' ', @flags),

  requires => {
    'perl'                  => 5.006,

    # Pragmatic and special modules
    'Carp'                  => 1.04,
    'version'               => 0,
    'warnings'              => 0,
    'strict'                => 0,

    # The tests are based on Test::More
    'Test::More'            => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'      => 0.084,

    # For the XS build process
    'ExtUtils::CBuilder'    => 0,
    'ExtUtils::ParseXS'     => 0,
  },
  recommends => {
    # The main interface
    'Math::Random::ISAAC'           => 0,

    # Author tests
    'Test::Perl::Critic'            => 1.01,
    'Perl::Critic'                  => 1.096,
    'Test::YAML::Meta'              => 0.11,
    'Test::Kwalitee'                => 1.01,
    'Test::Signature'               => 1.10,
    'Test::Pod'                     => 1.14,
    'Test::Pod::Coverage'           => 1.04,
    'Test::Portability::Files'      => 0.05,
    'Test::MinimumVersion'          => 0.008,
    'Test::LeakTrace'               => 0.07,
    'Statistics::Test::RandomWalk'  => 0,
    'Test::Without::Module'         => 0.17,
    'Test::DistManifest'            => 1.001002,
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Math-Random-ISAAC-XS-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Math-Random-ISAAC-XS',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Math-Random-ISAAC-XS',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Random-ISAAC-XS',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
