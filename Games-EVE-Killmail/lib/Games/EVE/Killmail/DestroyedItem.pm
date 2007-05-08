package Games::EVE::Killmail::DestroyedItem;

use 5.005;
use strict;
use Carp         'croak';
use Params::Util '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	name
	qty
	cargo
	};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Set defaults
	$self->{cargo} = 0 unless defined $self->{cargo};
	$self->{qty}   = 1 unless defined $self->{qty};

	return $self;
}

sub parse_string {
	my $class  = shift;
	my $string = _STRING(shift) or croak("Did not pass string to parse_string");
	my %attr   = ();
	if ( $string =~ s/\s+\(Cargo\)$//i ) {
		$attr{cargo} = 1;
	}
	if ( $string =~ s/\, Qty: (\d+)$//i ) {
		$attr{qty} = $1;
	}
	$attr{name} = $string;
	return $class->new( %attr );
}

1;
