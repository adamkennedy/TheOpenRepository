use inc::Module::Install;

all_from      'lib/CPAN/Index.pm';
requires      'IO::Zlib'       => 0;
requires      'version'        => '0.59';
requires      'Params::Util'   => '0.20';
requires      'Email::Address' => '1.80';
requires      'DBI'            => '1.50';
requires      'DBD::SQLite'    => '1.12';
requires      'DBIx::Class'    => '0.06002';
requires      'CPAN::Cache'    => '0.01';
test_requires 'Test::More'     => '0.47';
test_requires 'File::Spec'     => '0.80';
test_requires 'File::Copy'     => 0;
test_requires 'File::Remove'   => '0.34';

WriteAll;
