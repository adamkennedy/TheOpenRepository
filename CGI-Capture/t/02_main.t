#!/usr/bin/perl -w

# Main tests for CGI::Capture.
# There aren't many, but then CGI::Capture is so damned simple that
# there's really not that much to test.

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir(updir(), 'lib') );
	}
}

use Test::More tests => 4;
use CGI::Capture ();

# Create a new object
my $capture = CGI::Capture->new;
isa_ok( $capture, 'CGI::Capture' );

# Check that the use of IO::String for _stdin works
SCOPE: {
	my $input     = "foo\nbar\n";
	my $input_ref = \$input;
	ok( CGI::Capture->_stdin( $input_ref ), 'Set STDIN ok' );
	my $foo = <STDIN>;
	my $bar = <STDIN>;
	is( $foo, "foo\n", 'Read from STDIN ok' );
	is( $bar, "bar\n", 'Read from STDIN ok' );
}

exit(0);
