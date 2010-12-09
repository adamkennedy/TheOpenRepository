package ADAMK::SDL::Cube;

use 5.008;
use strict;
use warnings;
use OpenGL ':all';

# Precalculate the quad order
use vars qw{@QUADS};
BEGIN {
	my @indices = qw{
		4 5 6 7   1 2 6 5   0 1 5 4
		0 3 2 1   0 4 7 3   2 3 7 6
	};
	my @vertices = (
		[-1, -1, -1],
		[ 1, -1, -1],
		[ 1,  1, -1],
		[-1,  1, -1],
		[-1, -1,  1],
		[ 1, -1,  1],
		[ 1,  1,  1],
		[-1,  1,  1],
	);
	foreach my $face ( 0 .. 5 ) {
		foreach my $vertex ( 0 .. 3 ) {
			push @QUADS, $vertices[ $indices[ 4 * $face + $vertex ] ];
		}
	}
}





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}





######################################################################
# Main Methods

sub render {
	my $self = shift;

	glBegin(GL_QUADS);
	glVertex(@$_) foreach @QUADS;
	glEnd;

	return 1;
}

1;
