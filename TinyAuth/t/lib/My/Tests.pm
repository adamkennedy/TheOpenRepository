package My::Tests;

# Test utilities

use strict;
use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Exporter';
	@EXPORT  = qw{ cgi_cmp };
}

use Test::LongString ();





#####################################################################
# Test Functions

# Test that two HTML files match
sub cgi_cmp {
	my $left  = shift;
	my $right = shift;

	# Clean up the two sides
	$left  =~ s/^\s+//is;
	$left  =~ s/\s+$//is;
	$left  =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
	$right =~ s/^\s+//is;
	$right =~ s/\s+$//is;
	$right =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;

	Test::LongString::is_string( $left, $right, $_[0] );
}

1;
