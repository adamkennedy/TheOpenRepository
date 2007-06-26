#!/usr/bin/perl

# Main tests for CGI::Capture.
# There aren't many, but then CGI::Capture is so damned simple that
# there's really not that much to test.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use CGI::Capture ();

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

# Create a new object
my $cgi = CGI::Capture->new;
isa_ok( $cgi, 'CGI::Capture' );

# Do an actual capture, and convert to YAML
SCOPE: {
	ok( $cgi->capture, '->capture ok' );
	my $yaml = $cgi->as_yaml;
	isa_ok( $yaml, 'YAML::Tiny' );

	# Does the YAML document round-trip
	my $yaml2 = YAML::Tiny->read_string( $yaml->write_string );
	is_deeply( $yaml, $yaml2, 'YAML object round-trips ok' );

	# Generate the YAML document
	my $string = $cgi->as_yaml_string;
	ok( $string =~ /^---\nARGV:\s/, '->as_yaml returns a YAML document' );

	# Round-trip the CGI::Capture
	my $cgi2 = CGI::Capture->from_yaml_string( $string );
	is_deeply( $cgi, $cgi2, 'CGI::Capture round-trips ok' );
}

exit(0);
