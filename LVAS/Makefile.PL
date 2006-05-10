use inc::Module::Install;

name     'LVAS';
all_from 'lib/LVAS.pm';
requires 'IO::Socket::SSL';

WriteAll;
