#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use constant CONSTANTS => 122;

use Test::More tests => 7 + ( CONSTANTS * 2 );
use Test::NoWarnings;

use_ok( 'FBP::Perl' );

SKIP: {
	if ( $ENV{ADAMK_RELEASE} ) {
		skip( "Skipping Wx tests for release", (CONSTANTS * 2) + 5 );
	}
	eval "require Wx";
	skip( "Wx.pm is not available", (CONSTANTS * 2) + 5 ) if $@;

	# Confirm that all the event macros exist
	use_ok( 'Wx', ':everything' );
	use_ok( 'Wx::Html' );
	use_ok( 'Wx::Grid' );
	use_ok( 'Wx::DateTime' );
	use_ok( 'Wx::Calendar' );

	my %seen = ();
	%FBP::Perl::EVENT = %FBP::Perl::EVENT;
	foreach ( sort { $a->[1] cmp $b->[1] } grep { defined $_->[1] } values %FBP::Perl::EVENT ) {
		my $args   = $_->[0];
		my $symbol = $_->[1];
		next unless defined $symbol;
		next unless length  $symbol;
		next if $seen{$_->[1]}++;

		# Handle possibly unsupported elements
		next if $symbol eq 'EVT_DATE_CHANGED';
		next if $symbol eq 'EVT_TREE_ITEM_GETTOOLTIP';
		next if $symbol eq 'EVT_TREE_STATE_IMAGE_CLICK';

		my $found = eval "defined &Wx::Event::$symbol";
		ok( $found, "Wx::Event::$symbol macro exists" );

		if ( $args == 2 ) {
			eval "sub foo_$symbol { Wx::Event::$symbol( 1, 1, sub { } ) }";
		} else {
			eval "sub foo_$symbol { Wx::Event::$symbol( 1, sub { } ) }";
		}
		is( $@, '', "Wx::Event::$symbol compiled without error" );
	}
}
