package ADAMK::Changes::Release;

use 5.005;
use strict;
use Carp 'croak';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	string
	version
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { }, $class;

	# Get the paragraph strings
	$self->{string} = shift;
	my @lines  = split /\n/, $self->{string};

	# Find the version
	unless ( $lines[0] =~ /^([\d_\.]+)/ ) {
		croak("Failed to find version for release");
	}
	$self->{version} = $1;

	return $self;
}

1;
