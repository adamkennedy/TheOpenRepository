use inc::Module::Install 0.75;

all_from      'lib/File/Remove.pm';
requires      'File::Spec' => '0.84';
requires      'File::Copy' => 0;
requires      'File::Path' => 0;
requires      'File::Glob' => 0;
test_requires 'Test::More' => '0.42';

WriteAll;
