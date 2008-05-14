use inc::Module::Install;

all_from      'lib/File/Find/Rule/Perl.pm';
requires      'File::Find::Rule' => '0.20';
test_requires 'File::Spec'       => '0.82';
test_requires 'Test::More'       => '0.47';

WriteAll;
