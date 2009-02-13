use inc::Module::Install 0.79;

die "OS unsupported\n" if (not win32);

all_from       'lib/Perl/Dist/WiX.pm';
requires       'File::ShareDir'   => '1.00';
requires       'Perl::Dist'       => '1.12';
requires       'Data::UUID'       => '1.149';
requires       'List::MoreUtils'  => '0.07';
requires       'Module::CoreList' => '2.17';
build_requires 'Test::More'       => '0.47';
build_requires 'Test::Output'     => '0.11';
install_share;

WriteAll;
