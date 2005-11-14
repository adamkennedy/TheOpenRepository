#!/usr/bin/perl -w

# Basic functionality testing for File::Storable

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 26;
use File::Storable ();





#####################################################################
# Creation and general use

# Low-effort file
my $file1 = File::Storable->new( "foo",
	content_type => 'text/plain',
	FileName     => 'FOO.txt',
	foo          => 'bar',
	);
isa_ok( $file1, 'File::Storable' );
is( $file1->get_header('content_type'), 'text/plain', '->get_header(content_type) returns ok' );
is( $file1->get_header('filename'), 'FOO.txt', '->get_header(filename) returns ok' );
is( $file1->get_header('Foo'), 'bar', '->get_header(foo) returns ok' );
is( $file1->get_header('content_length'), 3, '->get_header(content_length) returns ok' );
is( $file1->set_header('FOO', 'baz'), 1, '->set_header(foo, value) returns true' );
is( $file1->get_header('foo'), 'baz', '->set_header(foo, value) changes header' );

my $content = $file1->get_content;
is( ref($content), 'SCALAR',  '->get_content returns a SCALAR ref' );
is( $$content, 'foo', '->get_content returns \"foo"' );





# Test known files for correct loading and type guess
my $file2 = File::Storable->from_file( catfile('t', 'data', 'image.gif') );
isa_ok( $file2, 'File::Storable' );
is( $file2->get_header('content_type'),   'image/gif', 'GIF content_type returns ok' );
is( $file2->get_header('filename'),       'image.gif', 'GIF filename returns ok' );
is( $file2->get_header('content_length'), 62,           'GIF length returns ok' );

my $file3 = File::Storable->from_file( catfile('t', 'data', 'image.jpg') );
isa_ok( $file3, 'File::Storable' );
is( $file3->get_header('content_type'),   'image/jpeg', 'GIF content_type returns ok' );
is( $file3->get_header('filename'),       'image.jpg',  'GIF filename returns ok' );
is( $file3->get_header('content_length'), 490,            'GIF length returns ok' );





# Freezing and thawing
foreach my $file ( $file1, $file2, $file3 ) {
	my $frozen = $file->freeze;
	my $is_string = defined $frozen and ! ref $frozen and length $frozen;
	ok( $is_string, '->freeze produces a string' );
	my $thawed = File::Storable->thaw( $frozen );
	isa_ok( $thawed, 'File::Storable' );
	is_deeply( $file, $thawed, 'Thawed File::Storable object matched original' );
}

exit(0);
