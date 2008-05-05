use inc::Module::Install;

name           'SQLite-Default';
all_from       'lib/SQLite/Default.pm';
requires       'Carp'           => 0;
requires       'File::Copy'     => 0;
requires       'Params::Util'   => '0.20';
requires       'File::ShareDir' => '0.05';
requires       'DBI'            => '1.56';
requires       'DBD::SQLite'    => '1.13';
test_requires 'Test::More'     => '0.42';
test_requires 'File::Spec'     => '0.80';
install_share;

WriteAll;
