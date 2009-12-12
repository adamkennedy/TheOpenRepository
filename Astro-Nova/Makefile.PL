use 5.008;
use strict;
use warnings;
use File::Spec; # todo configure_requires...
use Getopt::Long qw/GetOptions/;

my $no_compile_libnova = 0;
GetOptions(
  'no-compile' => \$no_compile_libnova,
);

my $novadir = 'libnova-0.13.0';
my $novadir_static_lib = File::Spec->catfile($novadir, 'src', '.libs', 'libnova.a');

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Astro::Nova',
    VERSION_FROM      => 'lib/Astro/Nova.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Astro/Nova.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I$novadir/src", # e.g., '-I. -I/usr/include/other'
    OBJECT            => "\$(O_FILES) $novadir_static_lib", # link all the C files too
    MYEXTLIB => $novadir_static_lib,
    TYPEMAPS => ['perlobject.map'],
);


sub MY::postamble {
  if ($no_compile_libnova) {
"
\$(MYEXTLIB): generate_structs
	#cd $novadir && ./configure --with-pic && \$(MAKE) \$(PASSTHRU)

generate_structs:
	\$(PERL) buildtools\$(DFSEP)makeNovaClass.pl
"
  }
  else {
"
\$(MYEXTLIB): generate_structs
	cd $novadir && ./configure --with-pic && \$(MAKE) \$(PASSTHRU)

generate_structs:
	\$(PERL) buildtools\$(DFSEP)makeNovaClass.pl
"
  }
}

