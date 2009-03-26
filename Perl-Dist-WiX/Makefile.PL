#! perl

use inc::Module::Install;

die "OS unsupported\n" if (not win32);

all_from       'lib/Perl/Dist/WiX.pm';
requires       'version'              => '0.76';
requires       'Alien::WiX'           => 'v0.300000';
requires       'Data::Dump::Streamer' => '2.08';
requires       'Data::UUID'           => '1.149';
requires       'Devel::StackTrace'    => '1.20';
requires       'Exception::Class'     => '1.22';
requires       'File::ShareDir'       => '1.00';
requires       'IO::String'           => '1.08';
requires       'List::MoreUtils'      => '0.07';
requires       'Module::CoreList'     => '2.17';
requires       'Object::InsideOut'    => '3.53';
test_requires  'Perl::Critic::More'   => '1.000' if ( $ENV{TEST_AUTHOR} );
requires       'Perl::Dist'           => '1.12';
requires       'Readonly'             => '1.03';
requires       'Scalar::Util'         => '1.19'; # Remove when 5.008 is minimum perl version.
requires       'Storable'             => '2.15'; # Remove when 5.008 is minimum perl version.
requires       'URI'                  => '1.35';
recommends     'Readonly::XS'         => '1.05';
test_requires  'Test::HasVersion'     => '0.012' if ( $ENV{TEST_AUTHOR} );
test_requires  'Test::MinimumVersion' => '0.008' if ( $ENV{TEST_AUTHOR} );
test_requires  'Test::More'           => '0.47';
test_requires  'Test::Output'         => '0.11';
test_requires  'Test::Perl::Critic'	  => '1.01'  if ( $ENV{TEST_AUTHOR} );
test_requires  'Test::Prereq'	      => '1.036' if ( $ENV{TEST_AUTHOR} );
test_requires  'Test::UseAllModules'  => '0.09';
requires       'Win32'                => '0.35';
resources      'repository'           => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX';
resources      'bugtracker'           => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX';
license        'perl';
install_share;

WriteAll;
