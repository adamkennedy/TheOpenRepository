#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::chmod           ();
use File::IgnoreReadonly  ();
use File::Spec::Functions ':ALL';
use File::Remove          'clear';





#####################################################################
# Create the readonly test file

my $file = catfile( 't', 'readonly.txt' );
clear( $file );
ok( ! -f $file, 'Test file does not exist' );
open( FILE, '>', $file )         or die "open: $!";
print FILE "This is a test file" or die "print: $!";
close( FILE )                    or die "close: $!";
File::chmod::chmod('a-w', $file);
ok( -f $file, 'Test file exists'      );
ok( -r $file, 'Test file is readable' );
SKIP: {
	unless ( File::IgnoreReadonly::WIN32 or ($< and $>) ) {
		skip( "Skipping test known to fail for root", 1 );
	}
	ok( ! -w $file, 'Test file is not writable' );
}





#####################################################################
# Main Tests

SCOPE: {
	# Create the guard object
	my $guard = File::IgnoreReadonly->new( $file );
	isa_ok( $guard, 'File::IgnoreReadonly' );

	# File should now be writable
	ok( -f $file, 'Test file exists'          );
	ok( -r $file, 'Test file is readable'     );
	ok( -w $file, 'Test file is not writable' );

	# Change the file
	open( FILE, '>', $file )           or die "open: $!";
	print FILE 'File has been changed' or die "print: $!";
	close( FILE )                      or die "close: $!";
}

# Destroy should have been fired.
ok( -f $file, 'Test file exists'      );
ok( -r $file, 'Test file is readable' );
SKIP: {
	unless ( File::IgnoreReadonly::WIN32 or ($< and $>) ) {
		skip( "Skipping test known to fail for root", 1 );
	}
	ok( ! -w $file, 'Test file is not writable' );
}

# File contents should be different
open( FILE, $file ) or die "open: $!";
my $line = <FILE>;
close( FILE )       or die "close: $!";
is( $line, 'File has been changed', 'File changed ok' );
