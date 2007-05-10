use strict;
use inc::Module::Install;

name           'Apache-Htpasswd-Shadow';
all_from       'lib/Apache/Htpasswd/Shadow.pm';
requires       'File::Copy'          => 0;
requires       'Apache::Htpasswd'    => 0;
build_requires 'File::Spec'          => '0.80';
build_requires 'Test::More'          => '0.42';
build_requires 'Test::File::Cleaner' => 0;

WriteAll;
