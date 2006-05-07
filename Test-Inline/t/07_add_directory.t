#!/usr/bin/perl -w

# Adding of entire directories

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
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Class::Autouse ':devel';
use Test::More tests => 9;
use Test::Inline ();





# Change to the correct directory
chdir catdir( 't', 'data', '06_multifile' ) or die "Failed to change to test directory";

# Create the Test::Inline object
ok( -d 't', 'Output directory exists' );
my $manifest = 't.manifest';
my $Inline = Test::Inline->new(
	output   => 't',
	manifest => $manifest,
	);
isa_ok( $Inline, 'Test::Inline' );

# Add the files
my $rv = $Inline->add( 'lib' );
is( $rv, 3, 'Adding lib results in 3 added scripts' );

# Save the file
my $out1 = catfile( 't', 'test_one.t' );
my $out3 = catfile( 't', 'test_three.t' );
my $out4 = catfile( 't', 'test_four.t' );

is( $Inline->save, 3, '->save returns 3 as expected' );
ok( -f $out1,     'Found test_one.t'   );
ok( -f $out3,     'Found test_three.t' );
ok( -f $out4,     'Found test_four.t'  );
ok( -f $manifest, 'Found manifest file' );

# Check the contents of the manifest
is( $Inline->manifest, <<END_MANIFEST, 'manifest contains expected content' );
t/test_four.t
t/test_one.t
t/test_three.t
END_MANIFEST

END {
	unlink $out1     if -f $out1;
	unlink $out3     if -f $out3;
	unlink $out4     if -f $out4;
	unlink $manifest if -f $manifest;
}
