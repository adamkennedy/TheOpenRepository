#!/usr/bin/perl -w

# Check Test::Inline::Extract support for older test styles

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
use File::Slurp ();
use Test::More tests => 7;
use Test::Inline::Extract ();





#####################################################################
# Test the examples from Inline.pm
{
	my $inline_file = File::Slurp::read_file(
		catfile( 't.data', '10_legacy_extract', 'Inline.pm' ),
		scalar_ref => 1,
		) or die "Failed to load Inline.pm test file";
	is( ref($inline_file), 'SCALAR', 'Loaded Inline.pm examples' );

	my $Extract = Test::Inline::Extract->new( $inline_file );
	isa_ok( $Extract, 'Test::Inline::Extract' );

	my $elements = $Extract->elements;
	is( ref($elements), 'ARRAY', '->elements returns an ARRAY ref' );
	is( scalar(@$elements), 3, '->elements returns three elements' );
	is( $elements->[0], 'package My::Pirate;', 'First element matches expected' );
	is( $elements->[1], <<'END_ELEMENT', 'Second element matches expected' );
=begin testing

my @p = is_pirate('Blargbeard', 'Alfonse', 'Capt. Hampton', 'Wesley');
is(@p,  2,   "Found two pirates.  ARRR!");

=end testing
END_ELEMENT
	is( $elements->[2], <<'END_ELEMENT', 'Third element matches expected' );
=for example begin

use LWP::Simple;
getprint "http://www.goats.com";

=for example end
END_ELEMENT
}
