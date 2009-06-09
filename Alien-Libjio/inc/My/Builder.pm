package My::Builder;

use strict;
use warnings;

use Module::Build;
our @ISA = ('Module::Build');

use Config '%Config';

use Cwd ();
use File::Spec ();

my $ORIG_DIR = Cwd::cwd();

sub _chdir_in {
  chdir File::Spec->catfile('libjio', 'libjio')
    or die("Failed to chdir to libjio/libjio: $!");
}
sub _chdir_back {
  chdir $ORIG_DIR or die("Failed to chdir to $ORIG_DIR: $!");
}

sub ACTION_code {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_code;
  if ($self->notes('build_libjio')) {
    _chdir_in();
    $rc = (system($self->notes('make')) == 0) ? 1 : 0;
    _chdir_back();
  }

  return $rc;
}

sub ACTION_install {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_install;
  if ($self->notes('build_libjio')) {
    _chdir_in();
    $rc = (system($self->notes('make'), 'install') == 0) ? 1 : 0;
    _chdir_back();
  }

  return $rc;
}

1;
