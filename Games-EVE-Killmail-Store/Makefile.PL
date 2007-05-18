use strict;
use inc::Module::Install;

name     'Games-EVE-Killmail-Store';
all_from 'lib/Games/EVE/Killmail/Store.pm';
requires 'Carp'                                => 0;
requires 'Params::Util'                        => '0.20';
requires 'Class::Default'                      => '1.50';
requires 'DBIx::Class'                         => 0;
requires 'DBIx::Class::Schema::Loader::SQLite' => 0;

WriteAll;
