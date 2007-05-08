use strict;
use inc::Module::Install;

name           'SimpleAuth';
author         'Adam Kennedy <adamk@cpan.org>';
abstract       'Simple Web-Based Authentication';
license        'perl';
all_from       'lib/SimpleAuth.pm';
requires       'Carp'        => 0;
requires       'DBIx::Class' => 0;
requires       'DBD::SQLite' => 0;
build_requires 'Test::More'  => '0.42';

WriteAll;
