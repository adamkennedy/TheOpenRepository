#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id$
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'WebService::UWO::Directory::Service',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/WebService/UWO/Directory/Student.pm',
  dynamic_config        => 0,
  create_readme         => 1,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  requires => {
    'perl'              => 5.006,
    'LWP::UserAgent'    => 0,
    'HTML::Entities'    => 0,

    # Pragmatic and special modules
    'Carp'              => 1.04,
    'version'           => 0.76,
    'warnings'          => 0,
    'strict'            => 0,

    # The tests are based on Test::More
    'Test::More'        => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
  },
  recommends => {
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
    'Test::Without::Module'         => 0.17,
    'Test::DistManifest'            => 1.001002,
  },
  conflicts => {
  },

  add_to_cleanup => [ 'WebService-UWO-Directory-Student-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/WebService-UWO-Directory-Student',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/WebService-UWO-Directory-Student',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UWO-Directory-Student',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
