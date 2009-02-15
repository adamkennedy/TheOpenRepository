use inc::Module::Install 0.79;

all_from      'lib/ORLite.pm';
requires      'File::Spec'     => winlike() ? '3.2701' : '0.80';
requires      'File::Temp'     => '0.20';
requires      'File::Path'     => '2.04';
requires      'File::Basename' => 0;
requires      'Params::Util'   => '0.33';
requires      'DBI'            => '1.58';
requires      'DBD::SQLite'    => '1.14';
test_requires 'Test::More'     => '0.47';
repository    'http://svn.ali.as/cpan/trunk/ORLite';

WriteAll;
