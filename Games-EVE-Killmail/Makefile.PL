use inc::Module::Install;

name           'Games-EVE-Killmail';
all_from       'lib/Games/EVE/Killmail.pm';
requires       'Carp'       => 0;
test_requires 'Test::More' => '0.42';

WriteAll;
