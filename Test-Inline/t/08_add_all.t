#!/usr/bin/perl -w

# Adding of all .pm files

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
use Test::More tests => 11;
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
my $rv = $Inline->add_all;
is( $rv, 5, 'Adding lib results in 3 added scripts' );

# Save the file
my $out1 = catfile( 't', 'test_one.t'    );
my $out3 = catfile( 't', 'test_three.t'  );
my $out4 = catfile( 't', 'test_four.t'   );
my $out5 = catfile( 't', 'test_allone.t' );
my $out6 = catfile( 't', 'test_alltwo.t' );

is( $Inline->save, 5, '->save returns 3 as expected' );
ok( -f $out1,     'Found test_one.t'    );
ok( -f $out3,     'Found test_three.t'  );
ok( -f $out4,     'Found test_four.t'   );
ok( -f $out5,     'Found test_allone.t' );
ok( -f $out6,     'Found test_alltwo.t' );
ok( -f $manifest, 'Found manifest file' );

# Check the contents of the manifest
is( $Inline->manifest, <<END_MANIFEST, 'manifest contains expected content' );
t/test_allone.t
t/test_alltwo.t
t/test_four.t
t/test_one.t
t/test_three.t
END_MANIFEST

END {
	unlink $out1     if -f $out1;
	unlink $out3     if -f $out3;
	unlink $out4     if -f $out4;
	unlink $out5     if -f $out5;
	unlink $out6     if -f $out6;
	unlink $manifest if -f $manifest;
}
