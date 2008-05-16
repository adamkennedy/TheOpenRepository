use inc::Module::Install;

license       'perl';
author        'Adam Kennedy <adamk@cpan.org';
all_from      'lib/ORLite.pm';
requires      'DBI'         => 0;
requires      'DBD::SQLite' => '1.13';
test_requires 'Test::More'  => '0.42';

WriteAll;
