use inc::Module::Install;

name           'DBIx-MySQLSequence';
all_from       'lib/DBIx/MySQLSequence.pm';
requires       'DBI'             => 0;
requires       'DBD::mysql'      => 0;
requires       'Params::Util'    => '0.26';
test_requires 'Test::More'      => '0.47';
test_requires 'File::Spec'      => '0.80';

WriteAll;
