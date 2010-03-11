#!perl

use inc::Module::Install 0.95;

name		    'Win32-Exe';
author		    'Audrey Tang <cpan@audreyt.org>';
author		    'Curtis Jewell <csjewell@cpan.org>';
abstract	    'Manipulate Win32 executable files';
license		    'perl';
install_script	'script/exe_update.pl';
version_from	'lib/Win32/Exe.pm';
repository      'http://svn.ali.as/cpan/trunk/Win32-Exe';
requires        'perl'	        => 5.006;
requires        'Parse::Binary' => 0.05;
build_requires	'Test::More'    => 0.47;

auto_include;
WriteAll;
