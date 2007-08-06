use strict;
use inc::Module::Install;

name           'CGI-Record';
all_from       'lib/CGI/Record.pm';
requires       'Carp'                => 0;
requires       'CGI::Capture'        => '1.09';
requires       'DBI'                 => 0;
requires       'DBD::SQLite'         => 0;
build_requires 'Test::More'          => '0.42';
build_requires 'Test::File::Cleaner' => 0;

WriteAll;
