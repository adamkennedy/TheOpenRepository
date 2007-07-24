package Imager::Search::RRGGBB;

# Basic search engine implemented in terms of web colours ( #003399 )

use strict;
use base 'Imager::Search';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# API Methods

sub small_transform {
	return \&__small_transform;
}

sub __small_transform {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
}

sub big_transform {
	return \&__big_transform;
}

sub __big_transform {
	my ($r, $g, $b, undef) = $_[0]->rgba;
	return sprintf("#%02X%02X%02X", $r, $g, $b);
};

sub newline_transform {
	return \&__newline_transform;
}

sub __newline_transform {
	my $chars = $_[0] * 7;
	return ".{$chars}";
}

1;
