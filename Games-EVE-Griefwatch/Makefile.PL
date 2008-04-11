use strict;
use inc::Module::Install;

name           'Games-EVE-Griefwatch';
author         'Adam Kennedy <adamk@cpan.org>';
abstract       'Extract killmails from griefwatch killboards';
license        'perl';
all_from       'lib/Games/EVE/Griefwatch.pm';
requires       'Carp'              => 0;
requires       'File::Slurp'       => '9999.12';
requires       'Params::Util'      => '0.20';
requires       'Object::Tiny'      => '1.00';
requires       'WWW::Mechanize'    => '1.22';
requires       'HTML::Tree'        => '3.23';
requires       'Object::Destroyer' => '2.00';
test_requires 'Test::More'        => '0.42';
test_requires 'LWP::Online'       => '0.02';

WriteAll;
