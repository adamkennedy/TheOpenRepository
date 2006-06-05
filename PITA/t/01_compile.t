#!/usr/bin/perl -w

# Compile-testing for PITA

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}


use Test::More tests => 25;

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );

	# Only three use statements should be enough
	# to load all of the classes (for now).
	use_ok( 'PITA'                             );
	use_ok( 'PITA::Guest'                      );
	use_ok( 'PITA::Guest::SupportServer'       );
	use_ok( 'PITA::Guest::Driver'              );
	use_ok( 'PITA::Guest::Driver::Local'       );
	use_ok( 'PITA::Guest::Driver::Image'       );
	use_ok( 'PITA::Guest::Driver::Image::Test' );
	use_ok( 'PITA::Guest::Storage'             );
	use_ok( 'PITA::Guest::Storage::Simple'     );
}

ok( $PITA::VERSION,      'PITA was loaded'      );
ok( $PITA::XML::VERSION, 'PITA::XML was loaded' );

foreach my $c ( qw{
	PITA::Guest
	PITA::Guest::Driver
	PITA::Guest::Driver::Local
	PITA::Guest::Driver::Image
	PITA::Guest::Driver::Image::Test
	PITA::Guest::SupportServer
	PITA::Guest::Storage
	PITA::Guest::Storage::Simple
} ) {
	eval "is( \$PITA::VERSION, \$${c}::VERSION, '$c was loaded and versions match' );";
}

# Confirm inheritance
ok( PITA::Guest::SupportServer->isa('Process'), '::SupportServer isa Process' );
ok( PITA::Guest::SupportServer->isa('Process::Backgroundable'), '::SupportServer isa Backgroundable' );

# Double check the method we use to find a workarea directory
my $workarea = File::Spec->tmpdir;
ok( -d $workarea, 'Workarea directory exists'       );
ok( -r $workarea, 'Workarea directory is readable'  );
ok( -w $workarea, 'Workarea directory is writeable' );

exit(0);
