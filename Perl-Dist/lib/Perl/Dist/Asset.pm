package Perl::Dist::Asset;

# Convenience base class for Perl::Dist assets

use strict;
use Carp           'croak';
use File::Spec     ();
use File::ShareDir ();
use URI::file      ();
use Params::Util   qw{ _STRING _CODELIKE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29_01';
}

use Object::Tiny qw{
	share
	url
	file
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Map share to url
	if ( $self->share ) {
		my ($dist, $name) = split /\s+/, $self->share;
		$self->trace("Finding $name in $dist... ");
		my $file = File::Spec->rel2abs(
			File::ShareDir::dist_file( $dist, $name )
		);
		unless ( -f $file ) {
			croak("Failed to find $file");
		}
		$self->{url} = URI::file->new($file)->as_string;
		$self->trace(" found\n");
	}

	# Check params
	unless ( _STRING($self->url) ) {
		croak("Missing or invalid url param");
	}

	# Create the filename from the url
	$self->{file} = $self->url;
	$self->{file} =~ s|.+/||;
	unless ( $self->file and length $self->file ) {
		croak("Missing or invalid file");
	}

	return $self;
}





#####################################################################
# Support Methods

sub trace {
	my $self = shift;
	if ( _CODELIKE($self->{trace}) ) {
		$self->{trace}->(@_);
	} else {
		print $_[0];
	}
}

1;
