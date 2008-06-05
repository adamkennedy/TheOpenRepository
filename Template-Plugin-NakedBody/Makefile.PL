use inc::Module::Install;

all_from      'lib/Template/Plugin/NakedBody.pm';
requires      'Template'   => '2.10';
test_requires 'Test::More' => '0.47';

WriteAll;
