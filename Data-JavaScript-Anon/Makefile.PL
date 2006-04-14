use inc::Module::Install;

name           'Data-JavaScript-Anon';
abstract       'Dump big dumb Perl structs to anonymous JavaScript structs';
author         'Adam Kennedy <cpan@ali.as>';
all_from       'lib/Data/JavaScript/Anon.pm';
build_requires 'File::Spec' => '0.82';
build_requires 'Test::More' => '0.47';

auto_install;
WriteAll;
