#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use constant CONSTANTS => 100;

use Test::More tests => 2 + CONSTANTS;
use Test::NoWarnings;

use_ok( 'FBP::Perl' );

SKIP: {
	eval "require Wx";
	skip("Wx.pm is not available", CONSTANTS) if $@;

	# Confirm that all the event macros exist
	use_ok( 'Wx', ':everything' );
	use_ok( 'Wx::HTML' );
	use_ok( 'Wx::DateTime' );

	%FBP::Perl::EVENT = %FBP::Perl::EVENT;
	foreach my $symbol ( sort grep { defined $_ } map { $_->[0] } values %FBP::Perl::EVENT ) {
		next unless defined $symbol;
		next unless length  $symbol;

		# Handle possibly unsupported elements
		next if $symbol eq 'EVT_DATE_CHANGED';

		my $found = eval "defined &Wx::Event::$symbol";
		ok( $found, "Wx::Event::$symbol macro exists" );
	}
}
