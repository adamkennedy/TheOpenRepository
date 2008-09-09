use inc::Module::Install 0.77;

all_from      'lib/Template/Provider/Preload.pm';
requires      'File::Spec'     => '0.80';
requires      'Class::Adapter' => '1.04';
requires      'Template'       => '2.10';
test_requires 'Test::More'     => '0.47';

WriteAll;
