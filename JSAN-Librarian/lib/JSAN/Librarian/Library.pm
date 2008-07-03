package JSAN::Librarian::Library;

# Implements a JavaScript::Librarian::Library object from a Config::Tiny
# index of a JSAN installed lib.

use strict;
use Config::Tiny          ();
use JSAN::Librarian::Book ();
use base 'JavaScript::Librarian::Library';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $Config = undef;
	if ( UNIVERSAL::isa(ref $_[0], 'Config::Tiny') ) {
		$Config = shift;
	} elsif ( defined $_[0] ) {
		$Config = Config::Tiny->read( $_[0] ) or return undef;
	} else {
		return undef;
	}

	# Remove any root entries
	delete $Config->{_};

	# Create the object
	my $self = bless {
		Config => $Config,
		}, $class;

	$self;
}

sub _load_item_list {
	my $self  = shift;
	my @books = ();
	foreach my $book ( keys %{$self->{Config}} ) {
		push @books, JSAN::Librarian::Book->new( $book, $self->{Config}->{$book} );
	}
	return \@books;
}

1;
