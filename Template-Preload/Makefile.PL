use inc::Module::Install;

all_from      'lib/Template/Provider/Preload.pm';
requires      'File::Spec'   => '0.82';
requires      'Template'     => '2.10';
test_requires 'Test::More'   => '0.47';

WriteAll;
