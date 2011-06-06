package EVE::TextPattern;

# Used to generate image recognition patterns for text

use strict;
use File::Spec              ();
use File::ShareDir          ();
use Imager::Search::Pattern ();

our $VERSION = '0.01';
our @ISA     = 'Imager::Search::Pattern';

# Cache the individual letter patterns
my %CACHE = ();

sub new {
	my $class = shift;
	my %param = @_;
	my $name  = $param{name} or die "Failed to provide a name";

	# Initialise
	my @lines  = ();
	my $height = undef;
	my $width  = undef;

	# Split the name into letters
	foreach my $letter ( split //, $name ) {
		# Load the individual character
		my $pattern = $class->get($letter);
		if ( @lines ) {
			# Not the first letter, add to existing
			unless ( $pattern->height == $height ) {
				die "Height mismatch for character '$letter'";
			}
			$width += $pattern->width;
			foreach ( 0 .. $height - 1 ) {
				$lines[$_] .= $pattern->lines->[$_];
			}
		} else {
			# First letter, initialise to it
			$height = $pattern->height;
			$width  = $pattern->width;
			@lines  = @{ $pattern->lines };
		}
	}

	return $class->SUPER::new(
		name   => $name,
		driver => 'Imager::Search::Driver::BMP24',
		height => $height,
		width  => $width,
		lines  => \@lines,
	);
}





######################################################################
# Support Methods

sub get {
	my $class  = shift;
	my $letter = shift;
	$CACHE{$letter} or
	$CACHE{$letter} = $class->load($letter);
}

sub load {
	my $class  = shift;
	my $letter = shift;
	my $file   = "text-$letter.bmp";
	my $path   = File::Spec->catfile(
		File::ShareDir::dist_dir('EVE'),
		'vision', $file,
	);
	unless ( -f $path ) {
		die "Failed to find file '$path' for character '$letter'";
	}
	return Imager::Search::Pattern->new(
		name   => $letter,
		driver => 'Imager::Search::Driver::BMP24',
		file   => $path,
		cache  => 1,
	);
}

1;
