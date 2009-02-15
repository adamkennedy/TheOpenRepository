use inc::Module::Install 0.79;

all_from      'lib/ORLite/Migrate.pm';
requires      'File::Spec'   => winlike() ? '3.2701' : '0.80';
requires      'File::Path'   => '2.04';
requires      'File::pushd'  => '1.00';
requires      'IPC::Run3'    => '0.042';
requires      'Params::Util' => '0.37';
requires      'Probe::Perl'  => '0.01';
requires      'DBI'          => '1.58';
requires      'DBD::SQLite'  => '1.14';
requires      'ORLite'       => '1.20';
test_requires 'Test::More'   => '0.47';

WriteAll;
