use inc::Module::Install;

name     'LVAS';
all_from 'lib/LVAS.pm';

require  'IO::Socket::SSL' => 0;

auto_install;
WriteAll;
