package JSAN::Librarian::Book;

# Implements a JavaScript::Librarian::Book. In our case, the id IS the path

use strict;
use base 'JavaScript::Librarian::Book';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $path  = shift or return undef;
	my %deps  = ref $_[0] eq 'HASH' ? %{shift()} : return undef;

	# Create the object
	my $self = bless {
		id      => $path,
		depends => [ keys %deps ],
		}, $class;

	$self;
}

sub path { $_[0]->{id} }

1;
