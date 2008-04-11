use strict;
use inc::Module::Install;

name                  'SVN-Tidy';
all_from              'lib/SVN/Tidy.pm';
requires              'Cwd';
requires              'FindBin';
requires              'File::Basename';
requires              'File::Spec'             => '0.80';
requires              'File::pushd'            => '0.24';
requires              'File::Which'            => '0.05';
requires              'File::Remove'           => '0.36';
requires              'File::Find::Rule'       => '0.27';
requires              'File::Find::Rule::Perl' => '0.03';
requires              'File::Find::Rule::VCS'  => '0.02';
test_requires        'Test::More'             => '0.42';
test_requires        'Test::Script'           => '1.02';
requires_external_bin 'svn';

WriteAll;
