use inc::Module::Install 0.77;

all_from      'lib/ORLite/Migrate.pm';
requires      'File::Spec'   => winlike() ? '3.2701' : '0.80';
requires      'File::pushd'  => 0;
requires      'IPC::Run3'    => 0;
requires      'Params::Util' => '0.33';
requires      'Probe::Perl'  => 0;
requires      'DBI'          => '1.58';
requires      'DBD::SQLite'  => '1.14';
requires      'ORLite'       => '1.16';
test_requires 'Test::More'   => '0.47';

WriteAll;
