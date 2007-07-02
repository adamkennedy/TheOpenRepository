#!/usr/bin/perl

# Testing PITA::Guest::Storage::Simple

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;

use PITA                         ();
use PITA::Guest::Storage::Simple ();
use File::Remove                 'remove';
use File::Spec::Functions        ':ALL';

# Set up an existing directory
my $storage_dir = catdir( 't', 'storage_simple' );
my $lock_file   = catfile( $storage_dir, 'PITA-Guest-Storage-Simple.lock' );
      if ( -d $storage_dir ) { remove( $storage_dir ) }
ok( ! -d $storage_dir, 'storage_simple does not exists' );
ok( mkdir($storage_dir), 'storage_simple created' );
END { if ( -d $storage_dir ) { remove( $storage_dir ) } }
ok( -d $storage_dir, 'storage_simple exists' );

# Find the test guest file
my $image_test = catfile( 't', 'guests', 'image_test.pita' );
ok( -f $image_test, 'Found image_test.pita test file' );





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

# Create a simple guest and add it
SCOPE: {
	my $guest = PITA::XML::Guest->read( $image_test );
	isa_ok( $xml, 'PITA::XML::Guest' );
	ok( $storage->add_guest($guest), '->add_guest ok' );
}

exit(0);
