package Module::Changes::ADAMK::Change;

use 5.005;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	string
	message
	author
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { string => shift }, $class;

	# Get the paragraph strings
	my @lines  = split /\n/, $self->{string};

	# A (FOO) at the end indicates an author
	if ( $lines[-1] =~ s/\s*\((\w+)\)\s*\z//s ) {
		$self->{author} = $1;
	}

	# Trim the lines and merge to get the long-form message
	$self->{message} = join ' ',
		grep { s/^\s+//; s/\s+\z//; $_ }
		@lines;
	$self->{message} =~ s/^-\s*//;

	return $self;
}

1;
