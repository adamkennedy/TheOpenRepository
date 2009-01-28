#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 23;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Perl::Dist::WiX' );
use_ok( 'Perl::Dist::WiX::Directory' );
use_ok( 'Perl::Dist::WiX::DirectoryTree' );
use_ok( 'Perl::Dist::WiX::Environment' );
use_ok( 'Perl::Dist::WiX::EnvironmentEntry' );
use_ok( 'Perl::Dist::WiX::Feature' );
use_ok( 'Perl::Dist::WiX::FeatureTree' );
use_ok( 'Perl::Dist::WiX::Filelist' );
use_ok( 'Perl::Dist::WiX::Files' );
use_ok( 'Perl::Dist::WiX::Installer' );
use_ok( 'Perl::Dist::WiX::Misc' );
use_ok( 'Perl::Dist::WiX::Registry' );
use_ok( 'Perl::Dist::WiX::StartMenu' );
use_ok( 'Perl::Dist::WiX::StartMenuComponent' );
use_ok( 'Perl::Dist::WiX::Base::Component' );
use_ok( 'Perl::Dist::WiX::Base::Entry' );
use_ok( 'Perl::Dist::WiX::Base::Fragment' );
use_ok( 'Perl::Dist::WiX::Files::Component' );
use_ok( 'Perl::Dist::WiX::Files::DirectoryRef' );
use_ok( 'Perl::Dist::WiX::Files::Entry' );
use_ok( 'Perl::Dist::WiX::Registry::Entry' );
use_ok( 'Perl::Dist::WiX::Registry::Key' );
