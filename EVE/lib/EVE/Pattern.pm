package EVE::Pattern;

use strict;
use Imager::Search::Pattern ();

our $VERSION = '0.01';
our @ISA     = 'Imager::Search::Pattern';

sub new {
	shift->SUPER::new(
		cache  => 1,
		driver => 'Imager::Search::Driver::BMP24',
		@_,
	);
}

sub sample {
	my $self  = shift;
	my $lines = $self->{lines};
	my $x     = shift;
	my $y     = shift;

	# Allow negative positions
	$x = $self->width  - $x if $x < 0;
	$y = $self->height - $y if $y < 0;

	# Extract the pixel at that location
	my $n   = 3 * $x;
	unless ( $lines->[$y] =~ /^(?:\\.|.){$n}((?:\\.|.){3})/ ) {
		die "Failed to sample the transparent pixel";
	}
	return "$1";
}

sub transparent {
	my $self  = shift;
	my $lines = $self->{lines};
	my $t     = shift;

	# Process each line to replace the sampled pixel with "any 3 bytes"
	foreach ( 0 .. $#$lines ) {
		$lines->[$_] =~ s/($t|(?:\\.|.){3})/ ($1 eq $t) ? '...' : $1 /ge;
	}

	return 1;
}

1;
