#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use Win32::File::Object;

# Test file name
my $path = catfile(qw{ t readonly.txt });
if ( -e $path ) {
	File::Remove::remove( \1, $path );
}
ok ( ! -e $path, 'The test file does not exist' );





#####################################################################
# Basic Test

# Create a file
open( FILE, '>', $path ) or die "open: $!";
print FILE "This is a temporary test file\n";
close( FILE ) or die "close: $!";
ok( -f $path, 'Created file ok' );

# Readonly should be false
my $file1 = Win32::File::Object->new( $path );
isa_ok( $file1, 'Win32::File::Object' );
is( $file1->readonly, 0, '->readonly is false' );

# Set readonly to true
is( $file1->readonly(2), 1, 'Set readonly ok' );
is( Win32::File::Object->new($path)->readonly, 0, '->readonly(value) does not autowrite' );

# Write the file
is( $file1->write, 1, '->write ok' );
is( Win32::File::Object->new($path)->readonly, 1, '->write worked' );
