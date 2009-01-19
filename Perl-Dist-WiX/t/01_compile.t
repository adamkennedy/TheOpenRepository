#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 20;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Perl::Dist::WiX' );
use_ok( 'Perl::Dist::WiX::Directory' );
use_ok( 'Perl::Dist::WiX::DirectoryTree' );
use_ok( 'Perl::Dist::WiX::Filelist' );
use_ok( 'Perl::Dist::WiX::Files' );
use_ok( 'Perl::Dist::WiX::Installer' );
use_ok( 'Perl::Dist::WiX::Misc' );
use_ok( 'Perl::Dist::WiX::Registry' );
use_ok( 'Perl::Dist::WiX::StartMenu' );
use_ok( 'Perl::Dist::WiX::StartMenuComponent' );
use_ok( 'Perl::Dist::WiX::Base::Component' );
use_ok( 'Perl::Dist::WiX::Base::Entry' );
use_ok( 'Perl::Dist::WiX::Base::Feature' );
use_ok( 'Perl::Dist::WiX::Base::Fragment' );
use_ok( 'Perl::Dist::WiX::Files::Component' );
use_ok( 'Perl::Dist::WiX::Files::DirectoryRef' );
use_ok( 'Perl::Dist::WiX::Files::Entry' );
use_ok( 'Perl::Dist::WiX::Registry::Entry' );
use_ok( 'Perl::Dist::WiX::Registry::Key' );



ok(
	$Perl::Dist::WiX::VERSION,
	'Perl::Dist::WiX loaded ok',
);

ok(
	$Perl::Dist::WiX::DirectoryTree::VERSION,
	'Perl::Dist::Types::WiX loaded ok',
);

ok(
	$Perl::Dist::WiX::File::VERSION,
	'Perl::Dist::WiX::File loaded ok',
);

ok(
	$Perl::Dist::WiX::Component::VERSION,
	'Perl::Dist::WiX::Component loaded ok',
);

ok(
	$Perl::Dist::WiX::Environment::VERSION,
	'Perl::Dist::WiX::Environment loaded ok',
);

ok(
	$Perl::Dist::WiX::Script::VERSION,
	'Perl::Dist::WiX::Script loaded ok',
);
