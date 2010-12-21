package SDL::Tutorial::3DWorld::Mesh;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.21';

use constant {
	VERTEX   => 1,
	MATERIAL => 2,
	FACE     => 3,
};

sub new {
	my $class = shift;
	my $self  = bless [
		[ undef ],
		[ ],
		[ ],
	], $class;
	return $self;
}

sub vertex {
	push @{ shift->[VERTEX] }, [ @_, 0, 0, 0 ];
}

sub triangle {
	my $self = shift;

	# Get the vertex list
	my ($v0, $v1, $v2) = @{$self->[VERTEX]}[@_];

	# Find vectors for two sides
	my $xa = $v0->[0] - $v1->[0];
	my $ya = $v0->[1] - $v1->[1];
	my $za = $v0->[2] - $v1->[2];
	my $xb = $v1->[0] - $v2->[0];
	my $yb = $v1->[1] - $v2->[1];
	my $zb = $v1->[2] - $v2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the cross product to each vector so that
	# vertex normals are averaged in proportion to face sizes.
	$v0->[3] += $xn;
	$v1->[3] += $xn;
	$v2->[3] += $xn;
	$v0->[4] += $yn;
	$v1->[4] += $yn;
	$v2->[4] += $yn;
	$v0->[5] += $zn;
	$v1->[5] += $zn;
	$v2->[5] += $zn;

	# Add the face to the face list
	push @{ $self->[FACE] }, \@_;
}

sub quad {
	my $self = shift;

	# Get the vertex set
	my ($v0, $v1, $v2, $v3) = @{$self->[VERTEX]}[@_];

	# Find vectors for two sides
	my $xa = $v0->[0] - $v1->[0];
	my $ya = $v0->[1] - $v1->[1];
	my $za = $v0->[2] - $v1->[2];
	my $xb = $v1->[0] - $v2->[0];
	my $yb = $v1->[1] - $v2->[1];
	my $zb = $v1->[2] - $v2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the cross product to each vector so that
	# vertex normals are averaged in proportion to face sizes.
	$v0->[3] += $xn;
	$v1->[3] += $xn;
	$v2->[3] += $xn;
	$v3->[3] += $xn;
	$v0->[4] += $yn;
	$v1->[4] += $yn;
	$v2->[4] += $yn;
	$v3->[4] += $yn;
	$v0->[5] += $zn;
	$v1->[5] += $zn;
	$v2->[5] += $zn;
	$v3->[5] += $zn;

	# Add the face to the face list
	push @{ $self->[FACE] }, \@_;
}

sub normalise {
	my $self = shift;
	foreach my $v ( @{$self->[VERTEX]} ) {
		my $l = sqrt( ($v->[0] ** 2) + ($v->[1] ** 2) + ($v->[2] ** 2) ) || 1;
		$v->[0] /= $l;
		$v->[1] /= $l;
		$v->[2] /= $l;
	}
	return 1;
}

sub draw {
	my $self = shift;
	
}

1;
