#!/usr/bin/env perl
# $File: //local/member/autrijus/Win32-Exe/Makefile.PL $ $Author: autrijus $
# $Revision: #6 $ $Change: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

use inc::Module::Install;

name		('Win32-Exe');
author		('Audrey Tang <cpan@audreyt.org>');
abstract	('Manipulate Win32 executable files');
license		('perl');
install_script	('script/exe_update.pl');
version_from	('lib/Win32/Exe.pm');

requires	(
    perl	    => '5.6.0',
    'Parse::Binary' => 0.05,
);
build_requires	('Test::More');

auto_include();
WriteAll( sign => 1 );
