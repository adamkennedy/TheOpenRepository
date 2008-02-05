#!/usr/bin/perl

# Build a trivial installer, from end to end

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Params::Util '_STRING';
use Win32::Wix ();

my $source_dir = catdir( 't', 'data', '02_trivial' );
ok( -d $source_dir, 'Found the test directory' );





#####################################################################
# Main Tests

# Create the script
my $script = Win32::Wix::Script->new(
	product_name         => 'Test Package',
	product_version      => 1,
	product_manufacturer => 'Test Manufacturer',
	package_description  => 'A Test Installer',
	package_comments     => 'Used for testing purposes',
	source_dir           => $source_dir,
	install_dir          => 'C:\\',
);
isa_ok( $script, 'Win32::Wix::Script' );
foreach ( qw{
	product_id
	product_name
	product_version
	product_manufacturer
	package_id
	package_description
	package_comments
	package_manufacturer
	source_dir
	install_dir
} ) {
	ok( !! _STRING($script->$_()), "Got a string from the ->$_ accessor" );
}
isa_ok( $script->xml_generator, 'XML::Generator' );

# Generate the XML fragment for the script
my $xml = $script->as_xml;
ok( $xml, '->as_xml returned ok' );

1;
