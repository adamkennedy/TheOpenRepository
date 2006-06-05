#!/usr/bin/perl -w

# Check that making an iso works like we expect

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
			);
	}
}

use Test::More;
use File::Remove 'remove';

# Can we load the test data package
eval {
	require PITA::Test::Image::Qemu;
};
if ( $@ ) {
	plan( 'skip_all' );
	exit(0);
}

plan( tests => 1 );
use_ok( 'PITA::XML'   );
use_ok( 'PITA::Guest' );

# Set the name of the test image (and remove redundant files)
my $pitafile = catfile( 't', 'ping.pita' );
      remove( $pitafile ) if -f $pitafile;
END { remove( $pitafile ) if -f $pitafile; }





#####################################################################
# Preparation

# Locate the test image
my $filename = PITA::Test::Image::Qemu->filename;
ok(      $filename, 'Got test image name'        );
ok(   -f $filename, 'Test image exists'          );
ok(   -r $filename, 'Test image is readable'     );
ok( ! -w $filename, 'Test image is not writable' );

# Create an xml element for the file
my $filexml = PITA::XML::File->new(
	filename => $filename,
	);
isa_ok( $filexml, 'PITA::XML::File' );

# Create a Qemu guest and save it, since we can only
# create live guest objects with on-disk files.
my $guestxml = PITA::XML::Guest->new(
	driver   => 'Qemu',
	memory   => 256,
	snapshot => 1,
	);
isa_ok( $guestxml, 'PITA::XML::Guest' );
ok( $guestxml->add_file( $filexml ), 'Added file to the guest config' );
ok( $guestxml->write( $pitafile ), "Saved guest pita file to $pitafile" );
ok( -f $pitafile, 'Wrote guest file ok' );





#####################################################################
# Main Testing

# Create the guest
my $guest = PITA::Guest->new( $pitafile );
isa_ok( $guest, 'PITA::Guest' );
ok( -f ($guest->files)[0]->filename, 'File exists' );
ok( $guest->ping, 'Guest pings ok' );

1;
