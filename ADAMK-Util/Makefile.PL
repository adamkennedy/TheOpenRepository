use strict;
use inc::Module::Install;

name                  'ADAMK-Util';
all_from              'lib/ADAMK/Util.pm';
requires              'Carp'         => 0;
requires              'IPC::Run3'    => 0;
requires              'File::Flat'   => 0;
requires              'File::Remove' => 0;
requires_external_bin 'chmod';
requires_external_bin 'which';

WriteAll;
