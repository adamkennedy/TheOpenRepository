#!/usr/bin/perl -w

# Testing PITA::Guest::Storage::Simple

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

# Until prove fixes it
local $ENV{PERL5LIB} = join ':', catdir('blib', 'lib'), catdir('blib', 'arch'), 'lib';

use Test::More tests => 7;

use PITA ();
use PITA::Guest::Storage::Simple ();
use File::Remove 'remove';

# Set up an existing directory
my $storage_dir = catdir( 't', 'storage_simple' );
my $lock_file   = catfile( $storage_dir, 'PITA-Guest-Storage-Simple.lock' );
      if ( -d $storage_dir ) { remove( $storage_dir ) }
ok( ! -d $storage_dir, 'storage_simple does not exists' );
ok( mkdir($storage_dir), 'storage_simple created' );
END { if ( -d $storage_dir ) { remove( $storage_dir ) } }
ok( -d $storage_dir, 'storage_simple exists' );





#####################################################################
# Test a basic existing object

# Create a basic storage object
my $storage = PITA::Guest::Storage::Simple->new(
	storage_dir => $storage_dir,
	);
isa_ok( $storage, 'PITA::Guest::Storage::Simple' );
isa_ok( $storage, 'PITA::Guest::Storage' );
is( $storage->storage_dir, $storage_dir, '->storage_dir returns as expected' );
is( $storage->storage_lock, $lock_file,  '->storage_lock returns as expected' );

exit(0);
