use 5.006002;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long 'GetOptions';
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $DEBUG = 0;
GetOptions(
  'debug' => \$DEBUG,
);

my $CC = 'g++';

WriteMakefile1(
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006002',
    META_MERGE => {
      resources => {
        repository => 'http://svn.ali.as/cpan/trunk/PPI-XS-Tokenizer',
      },
    },
    BUILD_REQUIRES => {
      'Test::More' => 0,
      'Test::NoWarnings' => 0,
    },

    NAME              => 'PPI::XS::Tokenizer',
    VERSION_FROM      => 'lib/PPI/XS/Tokenizer.pm', # finds $VERSION
    PREREQ_PM         => {
      'PPI' => 0,
      'ExtUtils::XSpp' => '0.06',
    },
    ABSTRACT_FROM => 'lib/PPI/XS/Tokenizer.pm',
    AUTHOR => 'Shmuel Fomberg <semuelf@cpan.org>',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => ($DEBUG ? '-O0 -g' : '-O2'),
    INC               => '-I. -Isrc',
    OBJECT            => '$(O_FILES)',
    XSOPT             => '-C++ -hiertype',
    TYPEMAPS          => ['perlobject.map'],
    CC                => $CC,
    LD                => '$(CC)',
    ($DEBUG ? ('CCFLAGS' => '-g3 -O0') : ()),
);

if  (grep $_ eq "--regen-constants", @ARGV) {
  require ExtUtils::Constant;
  print "# Regenerating constants...\n";
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
    # LineTokenizeResults
    qw(
      found_token
      reached_eol
      tokenizing_fail
    ),
  );
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'PPI::XS::Tokenizer::Constants',
                                     NAMES        => [map { +{name => $_, macro => 1} } @names],
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy($file, $fallback) or die "Can't copy $file to $fallback: $!";
  }
}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}


sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}

