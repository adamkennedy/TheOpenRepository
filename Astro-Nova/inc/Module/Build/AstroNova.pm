package Module::Build::AstroNova;
use 5.006;
use warnings;
use strict;

use Module::Build;
our @ISA = 'Module::Build';

use File::Spec;
use Config;

our $NovaDir = 'libnova-0.13.0';
our $NovaDirStaticLib = File::Spec->catfile($NovaDir, 'src', '.libs', 'libnova'.$Config::Config{lib_ext});
our $Typemaps = ['mytype.map', 'perlobject.map'];

sub ACTION_code {
  my $self = shift;
  $self->depends_on("libnova");
  $self->depends_on("fixtypemaps");
  $self->depends_on("structs");
  return $self->SUPER::ACTION_code(@_);
}

sub ACTION_libnova {
  my $self = shift;
  if (-f $NovaDirStaticLib) {
    $self->log_info("libnova already built, skipping re-build.\n");
    return 1;
  }
  $self->log_info("Building libnova for static linking...\n");
  my $oldcwd = Cwd::cwd();
  chdir($NovaDir) or die "Failed to chdir to '$NovaDir'";
  system("./configure", "--with-pic") and die "Failed to configure libnova";
  system("make") and die "Failed to compile libnova";
  chdir $oldcwd;
  if (-f $NovaDirStaticLib) {
    $self->log_info("Built libnova and found static library. All is well.\n");
  }
  else {
    die "Tried to build libnova, but the static library isn't where I expected it ($NovaDirStaticLib)";
  }
  return 1;
}

sub ACTION_fixtypemaps {
  my $self = shift;
  require ExtUtils::Typemap;
  if (-f 'typemap') {
    $self->log_warn("typemap exists... overwriting\n");
    unlink('typemap');
  }
  my $typemap = ExtUtils::Typemap->new(file => 'typemap');
  $self->log_info("Merging typemaps to 'typemap'...\n");
  foreach my $typemap_file (@$Typemaps) {
    die "Can't find typemap file '$typemap_file'"
      if not -f $typemap_file;
    $typemap->merge(typemap => ExtUtils::Typemap->new(file => $typemap_file));
  }
  $typemap->write();
  $self->add_to_cleanup('typemap');
  return 1;
}

sub ACTION_structs {
  my $self = shift;
  $self->depends_on("libnova");
  $self->depends_on("fixtypemaps");
  $self->log_info("Generating XS/Structs.xs...\n");
  system($^X, File::Spec->catfile("buildtools", "makeNovaClass.pl"))
    and die "Failed to build XS/Structs.xs";
  return 1;
}

1;
