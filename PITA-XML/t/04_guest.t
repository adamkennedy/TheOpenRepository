#!/usr/bin/perl -w

# Unit tests for the PITA::XML::Request class

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

use Test::More tests => 22;
use PITA::XML ();

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}





#####################################################################
# Basic tests

# Create a new object
SCOPE: {
	my $dist = PITA::XML::Guest->new(
		driver => 'Local',
		);
	isa_ok( $dist, 'PITA::XML::Guest' );
	is( $dist->driver, 'Local', '->driver matches expected' );
	is_deeply( [ $dist->files ], [], '->files matches expected (list)' );
	is( scalar($dist->files), 0, '->files matches expected (scalar)' );
	is_deeply( $dist->config, {}, '->config returns an empty hash' );
}

# Create another one with more details
my $file = PITA::XML::File->new(
	filename => 'guest.img',
	digest   => 'MD5.abcdefabcd0123456789abcdefabcd01',
	resource => 'hda',
	);
isa_ok( $file, 'PITA::XML::File' );

my @params = (
	driver   => 'Image::Test',
	memory   => 256,
	snapshot => 1,
	);
SCOPE: {
	my $dist = PITA::XML::Guest->new( @params );
	isa_ok( $dist, 'PITA::XML::Guest' );
	ok( $dist->add_file( $file ), '->add_file ok' );
	is( $dist->driver,  'Image::Test', '->driver matches expected' );
	is( scalar($dist->files), 1, '->files returns as expected (scalar)' );
	is( ($dist->files)[0]->filename, 'guest.img', '->filename returns undef'  );
	is( ($dist->files)[0]->digest->as_string, 'MD5.abcdefabcd0123456789abcdefabcd01',
		'->digest returns undef' );
	is_deeply( $dist->config, { memory => 256, snapshot => 1 },
		'->config returns the expected hash' );
}

# Load the same thing from a file
SCOPE: {
	my $filename = catfile( 't', 'samples', 'guest.pita' );
	ok( -f $filename, 'Sample Guest file exists' );
	my $dist = PITA::XML::Guest->read( $filename );
	isa_ok( $dist, 'PITA::XML::Guest' );
	is( $dist->driver,  'Image::Test', '->driver matches expected' );
	is( ($dist->files)[0]->filename, 'guest.img', '->filename returns undef'  );
	is( ($dist->files)[0]->digest->as_string, 'MD5.abcdefabcd0123456789abcdefabcd01',
		'->md5sum returns undef' );
	is_deeply( $dist->config, { memory => 256, snapshot => 1 },
		'->config returns the expected hash' );
	my $made = PITA::XML::Guest->new( @params );
	isa_ok( $made, 'PITA::XML::Guest' );
	ok( $made->add_file( $file ), '->add_file ok' );
	is_deeply( $dist, $made, 'File-loaded version exactly matches manually-created one' );
}

exit(0);
