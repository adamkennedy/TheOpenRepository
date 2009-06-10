#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 7351 2009-06-02 14:20:21Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

use strict;
use warnings;

use lib 'inc';
use My::Builder;

my $builder = My::Builder->new(
  module_name           => 'Alien::Libjio',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/Alien/Libjio.pm',
  dynamic_config        => 1,
  create_readme         => 1,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  requires => {
    'perl'              => 5.006,

    # Pragmatic and special modules
    'Carp'              => 1.04,
    'version'           => 0.76,
    'warnings'          => 0,
    'strict'            => 0,

    # Utilities to find compile information
    'ExtUtils::Liblist'       => 0,
    'IPC::Open3'              => 0,
    'Cwd'                     => 0,
    'File::Spec'              => 0,
  },
  build_requires => {
    # User tests for good functionality
    'Test::More'              => 0.62,
    'Test::NoWarnings'        => 0.084,

    # For the C compiling process
    'ExtUtils::CBuilder'      => 0,
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
    'Test::DistManifest'            => 1.001002,
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
  if ($ENV{MAKE}) {
    $make = $ENV{MAKE};
  }
  else {
    use Config '%Config';
    $make = $Config{make};
  }
  $make = $builder->prompt('What is your system "make" command?', $make);

  $builder->notes(make => $make);

  # Figure out if we should do a full install
  my $extra = $builder->y_n('libjio includes other files including Python ' .
    'and Ruby bindings. Install them too?', 'n');
  $builder->notes(extra => $extra);
}

$builder->create_build_script();
