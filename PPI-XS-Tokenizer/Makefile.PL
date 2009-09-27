use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $CC = 'g++';

WriteMakefile(
    NAME              => 'PPI::XS::Tokenizer',
    VERSION_FROM      => 'lib/PPI/XS/Tokenizer.pm', # finds $VERSION
    PREREQ_PM         => {
      'PPI' => 0,
      'ExtUtils::XSpp' => '0.04',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PPI/XS/Tokenizer.pm', # retrieve abstract from module
       AUTHOR         => 'Shmuel Fomberg <semuelf@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Isrc', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
     OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++ -hiertype',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => $CC,
    'LD'                => '$(CC)',
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

