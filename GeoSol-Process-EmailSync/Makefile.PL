use inc::Module::Install;

use 5.005;
use File::Spec ();

# Can we find the GeoSol project directory
unless ( $ENV{GEOSOL_ROOT} ) {
	print "Required environment variable GEOSOL_ROOT is not defined\n";
	exit(255);
}
unless ( $ENV{GEOSOL_ROOT} ) {
	print "Required environment variable GEOSOL_ROOT does not exist at '$ENV{GEOSOL_ROOT}'\n";
	exit(255);
}

# Locate the GeoSol modules
unshift @INC, File::Spec->catdir( $ENV{GEOSOL_ROOT}, 'cgi-bin', 'lib' );

name           'GeoSol-Process-EmailSync';
license        'commercial';
author         'Adam Kennedy <adam@phase-n.com>';
all_from       'lib/GeoSol/Process/EmailSync.pm';
requires       'base'           => 0;
requires       'Carp'           => 0;
requires       'File::Spec'     => '0.80';
requires       'Params::Util'   => '0.10';
requires       'Process'        => '0.16';
requires       'LVAS'           => '0.01';

# These two MUST be loaded in this order
requires       'GeoSol::Config' => 0;
requires       'GeoSol'         => 0;

build_requires 'Test::More'     => '0.47';

auto_install;
WriteAll;
