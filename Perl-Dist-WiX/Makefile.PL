use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/WiX.pm';
requires       'File::ShareDir'  => '1.00';
requires       'Perl::Dist'      => '1.04';
requires       'Data::UUID'      => 0;
requires       'List::MoreUtils' => 0;
build_requires 'Test::More'      => '0.47';
install_share;

WriteAll;
