use inc::Module::Install;

all_from      'lib/ORLite.pm';
requires      'File::Spec'  => '0.80';
requires      'DBI'         => '1.58';
requires      'DBD::SQLite' => '1.14';
test_requires 'Test::More'  => '0.47';

WriteAll;
