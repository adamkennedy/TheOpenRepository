use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/WiX.pm';
requires       'Moose'       => '0.58';
requires       'Perl::Dist'  => '1.04';
build_requires 'Test::More ' => '0.47';
install_share;

WriteAll;
