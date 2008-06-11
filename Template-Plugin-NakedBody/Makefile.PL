use inc::Module::Install;

name          'Template-Plugin-NakedBody';
requires      'Template'   => '2.10';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec' => '0.82';

WriteAll;
