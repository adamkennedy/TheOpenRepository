use inc::Module::Install;

name           'Task-StrawberryPerl';
all_from       'lib/Task/StrawberryPerl.pm';
requires       'CPAN'                  => '1.87';
requires       'File::Spec'            => '3.18';
requires       'Test::More'            => '0.62';
requires       'Test::Builder'         => '0.62';
requires       'Test::Builder::Tester' => '1.02';
requires       'Test::Harness'         => '2.60';
requires       'File::Temp'            => '0.16';
requires       'Term::ReadKey'         => '2.30';
requires       'Term::ReadLine::Perl'  => '1.0302';
requires       'Archive::Tar'          => '1.29';
requires       'Archive::Zip'          => '1.16';
requires       'YAML'                  => '0.58';
requires       'Getopt::Long'          => '2.35';
requires       'ExtUtils::MakeMaker'   => '6.30';
requires       'ExtUtils::Install'     => '1.40';
requires       'Module::Build'         => '0.2801';
requires       'File::HomeDir'         => '0.58';
requires       'Compress::Zlib'        => '1.41';
requires       'Digest::SHA'           => '5.41';
requires       'Text::Glob'            => '0.06';
requires       'LWP'                   => '5.805';

WriteAll;
