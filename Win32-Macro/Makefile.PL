use strict;
use inc::Module::Install;

name           'Win32-Macro';
abstract       'Write macros for Win32 in a Perlish style';
author         'Adam Kennedy <adamk@cpan.org>';
license        'perl';
version        '5.008';
requires       'Carp'               => 0;
requires       'Exporter'           => 0;
requires       'Imager'             => 0;
requires       'Win32API::Registry' => 0;
test_requires 'Test::More'   => 0;
cc_files       'lib/Win32/Macro/Internals.c';

require ExtUtils::Constant;
ExtUtils::Constant::WriteConstants(
	NAME  => 'Win32::Macro::Internals',
	NAMES => [ qw{
		GW_CHILD
		GW_HWNDFIRST
		GW_HWNDLAST
		GW_HWNDNEXT
		GW_HWNDPREV
		GW_OWNER
		SW_HIDE
		SW_MAXIMIZE
		SW_MINIMIZE
		SW_RESTORE
		SW_SHOW
		SW_SHOWDEFAULT
		SW_SHOWMAXIMIZED
		SW_SHOWMINIMIZED
		SW_SHOWMINNOACTIVE
		SW_SHOWNA
		SW_SHOWNOACTIVATE
		SW_SHOWNORMAL
	} ],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'lib/Win32/Macro/const-c.inc',
	XS_FILE      => 'lib/Win32/Macro/const-xs.inc',
);

WriteAll;
