use strict;
use inc::Module::Install;

name           'EVE-Macro';
license        'proprietary';
author         'Adam Kennedy <adamk@cpan.org>';
all_from       'lib/EVE/Macro/Object.pm';
requires       'File::Spec'       => 0;
requires       'File::HomeDir'    => 0;
requires       'Params::Util'     => 0;
requires       'Config::Tiny'     => 0;
requires       'Win32::GuiTest'   => 0;
build_requires 'Test::More'       => 0;

WriteAll;

1;
