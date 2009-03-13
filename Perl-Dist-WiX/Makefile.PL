#! perl

use inc::Module::Install 0.79;

die "OS unsupported\n" if (not win32);

all_from       'lib/Perl/Dist/WiX.pm';
requires       'version'             => '0.76';
requires       'Data::UUID'          => '1.149';
requires       'Exception::Class'    => '1.22';
requires       'File::ShareDir'      => '1.00';
requires       'List::MoreUtils'     => '0.07';
requires       'Module::CoreList'    => '2.17';
requires       'Object::InsideOut'   => '3.53';
requires       'Perl::Dist'          => '1.12';
requires       'Readonly'            => '1.03';
recommends     'Readonly::XS'        => '1.05';
test_requires  'Test::More'          => '0.47';
test_requires  'Test::Output'        => '0.11';
test_requires  'Test::UseAllModules' => '0.09';
requires       'Win32'               => '0.35';
resources      'repository'          => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX';
resources      'bugtracker'          => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX';
license        'perl';
install_share;

WriteAll;
