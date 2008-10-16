use inc::Module::Install 0.77;

all_from      'lib/File/Remove.pm';
requires      'File::Copy' => 0;
requires      'File::Path' => 0;
requires      'File::Glob' => 0;
requires      'File::Spec' => '3.2701';
requires      'Cwd'        => '3.2701';
test_requires 'Test::More' => '0.42';

WriteAll;
