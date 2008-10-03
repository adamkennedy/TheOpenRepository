use inc::Module::Install;

name     'Perl-Dist-CatInABox';
all_from 'lib/Perl/Dist/CatInABox.pm';
requires 'Perl::Dist::Strawberry';
author   'Kieren Diment <zarquon@cpan.org>';
install_script 'perldist_catinabox';


build_requires 'Test::More';

auto_install;

WriteAll;

