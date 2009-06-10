# My::Builder
#  A local Module::Build subclass for installing libjio
#
# $Id: ISAAC.pm 7057 2009-05-12 22:51:01Z FREQUENCY@cpan.org $
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

package My::Builder;

use strict;
use warnings;

use Module::Build;
our @ISA = ('Module::Build');

use Config '%Config';

use Cwd ();
use File::Spec ();
use Carp ();

my $ORIG_DIR = Cwd::cwd();

# These are utility commands for getting into and out of our build directory
sub _chdir_or_die {
  my ($dir) = @_;
  chdir $dir or Carp::croak("Failed to chdir to $dir: $!");
}
sub _chdir_back {
  chdir $ORIG_DIR or Carp::croak("Failed to chdir to $ORIG_DIR: $!");
}

sub ACTION_code {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_code;
  if ($self->notes('build_libjio')) {
    # Get into our build directory; either libjio (all) or libjio/libjio
    # (bindings only)
    if ($self->notes('extra')) {
      _chdir_or_die('libjio');
    }
    else {
      _chdir_or_die(File::Spec->catfile('libjio', 'libjio'));
    }

    # Run the make system to do the rest
    $rc = (system($self->notes('make')) == 0) ? 1 : 0;
    _chdir_back();
  }

  return $rc;
}

sub ACTION_install {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_install;
  if ($self->notes('build_libjio')) {
    # Get into our build directory
    if ($self->notes('extra')) {
      _chdir_or_die('libjio');
    }
    else {
      _chdir_or_die(File::Spec->catfile('libjio', 'libjio'));
    }

    # Run the make system to do the rest
    $rc = (system($self->notes('make'), 'install') == 0) ? 1 : 0;
    _chdir_back();
  }

  return $rc;
}

1;
