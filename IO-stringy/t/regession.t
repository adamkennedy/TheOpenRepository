#!/usr/bin/perl -w

# Holds regression tests

use strict;
use Test::More tests => 16;

# Load the modules to be tested during this file
use_ok( 'IO::Scalar' );





#####################################################################
# CPAN Bug #12719

diag("CPAN #12719 - broken seek/tell implementation");
diag("Testing against IO::Scalar $IO::Scalar::VERSION");

# Reconfirm that seek for read works
SCOPE: {
	my $string = "foo\nbar\n";
	my $fh     = IO::Scalar->new( \$string );
	isa_ok( $fh, 'IO::Scalar' );
	is( scalar(<$fh>), "foo\n", '<$fh> reads one line'         );
	ok(         $fh->seek(0,0), '->seek(0,0) returns true'     );
	is( scalar(<$fh>), "foo\n", '<$fh> returns the same value' );
	is( scalar(<$fh>), "bar\n", '<$fh> returns the next value' );
}

SCOPE: {
	# Create an empty IO::Scalar
	my $string = '';
	my $fh = IO::Scalar->new( \$string );
	isa_ok( $fh, 'IO::Scalar' );

	# Write to it
	ok( $fh->print('four'), '->print(four) returns true' );
	is( $fh->tell, 4, '->tell returns 4'                 );
	is( $string, 'four', 'String is set correctly'       );

	# Seek back to the start
	ok( $fh->seek( 0, 0 ), '->seek(0,0) returns true' );
	is( $fh->tell, 0, '->tell returns 0'              );
	is( $string, 'four', 'String is unchanged'        );

	# Overwrite the first 3 chars
	ok( $fh->print('bar'), '->print(bar) returns true'   );
	is( $fh->tell, 3, '->tell back to 3 again'           );
	is( $string, 'barr', 'First three chars are changed' );
}

1;
