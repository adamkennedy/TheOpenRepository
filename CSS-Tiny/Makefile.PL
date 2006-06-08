use inc::Module::Install;

name           'CSS-Tiny';
author         'Adam Kennedy<cpan@ali.as>';
version_from   'lib/CSS/Tiny.pm';
build_requires 'File::Spec'     => '0.80';
build_requires 'Test::More'     => '0.47';

WriteAll;
