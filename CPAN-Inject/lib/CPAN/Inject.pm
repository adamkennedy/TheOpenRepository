package CPAN::Inject;

use strict;
use Params::Util   '_STRING';
use File::Basename ();
use CPAN;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check where we are going to write to
	my $sources = $self->sources;
	unless ( _STRING($sources) ) {
		Carp::croak("Did not probide a sources param, or not a string");
	}
	unless ( -d $sources ) {
		Carp::croak("The directory '$sources' does not exist");
	}
	unless ( -w $sources ) {
		Carp::croak("No write permissions to '$sources'");
	}

	# Check for a default author name
	unless ( $self->author ) {
		$self->{author} = 'LOCAL';
	}
	unless ( _STRING($self->author) and $self->author =~ /^[A-Z]{3,}$/ ) {
		Carp::croak("The author name '"
			. $self->author
			. "' is not a valid author string");
	}

	$self;
}

sub add {
	my $self = shift;
	my $file = shift;
	unless ( $file and -f $file and -r $file ) {
		Carp::croak("Did not provide a file name, or does not exist");
	}

	# Find the location to copy it to
	
}

sub author_path {
	my $self = shift;
	File::Spec->catdir(
		substr( $self->author, 0, 1 ),
		substr( $self->author, 0, 2 ),
		        $self->author,
		);
}

sub file_path {
	my $self = shift;
	File::Spec->catfile(
		
}

1;
