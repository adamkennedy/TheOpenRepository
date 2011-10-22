#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use constant CONSTANTS => 140;

use Test::More tests => 7 + CONSTANTS;
use Test::NoWarnings;

use_ok( 'FBP::Perl' );

SKIP: {
	if ( $ENV{ADAMK_RELEASE} ) {
		skip( "Skipping Wx tests for release", CONSTANTS + 5 );
	}
	eval "require Wx";
	skip( "Wx.pm is not available", CONSTANTS + 5 ) if $@;

	# Confirm that all the event macros exist
	use_ok( 'Wx', ':everything' );
	use_ok( 'Wx::Html' );
	use_ok( 'Wx::Grid' );
	use_ok( 'Wx::DateTime' );
	use_ok( 'Wx::Calendar' );

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
