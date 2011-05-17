use strict;
use inc::Module::Install;

name           'Oz';
author         'Adam Kennedy <adamk@cpan.org>';
abstract       'Interface for executing Oz applications';
license        'proprietary';
requires       'Carp'         => 0;
requires       'File::Spec'   => '0.80';
requires       'File::Temp'   => '0.18';
requires       'File::pushd'  => '0.99';
requires       'File::Slurp'  => '9999.12';
requires       'File::Which'  => '0.05';
requires       'IPC::Run3'    => '0.037';
requires       'Params::Util' => '0.20';
build_requires 'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.42';

# We need the oz compiler (I think)
requires_external_bin 'ozc';
requires_external_bin 'ozengine';

WriteAll;
