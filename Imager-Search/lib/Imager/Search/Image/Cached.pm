package Imager::Search::Image::Cached;

# An image to be searched, already transformed

use strict;
use base 'Imager::Search::Image';
use Carp        ();
use File::Slurp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}





#####################################################################
# Main Methods

sub read {
	my $class = shift;


	# Check the file
	my $file = shift;
	Carp::croak( 'You did not specify a file name' )          unless $file;
	Carp::croak( "File '$file' does not exist" )              unless -e $file;
	Carp::croak( "'$file' is a directory, not a file" )       unless -f _;
	Carp::croak( "Insufficient permissions to read '$file'" ) unless -r _;

	# Slurp in the raw file
	my $scalar_ref = File::Slurp::read_file( $file, scalar_ref => 1 );

	# Strip off the headers and parse them
	unless ( $$scalar_ref =~ s/^(.+?)\n\n//s ) {
		Carp::croak("Failed to find any headers in file");
	}
	my @headers = split /\n/, $1;
	my %self    = ();
	foreach ( @headers ) {
		unless ( /^(.+?):\s*(.+?)\s*$/ ) {
			Carp::croak("Invalid header line '$_'");
		}
		$self{$1} = $2;
	}

	# Hand off to create the object
	return $class->new( %self, string => $scalar_ref );
}

1;
