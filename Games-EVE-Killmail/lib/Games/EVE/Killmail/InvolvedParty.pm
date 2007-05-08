package Games::EVE::Killmail::InvolvedParty;

use 5.005;
use strict;
use Carp         'croak';
use Params::Util qw{ _ARRAY };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	final_blow
	name
	security
	alliance
	corp
	ship
	weapon
};






#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Set some defaults
	$self->{final_blow} = 0  unless defined $self->{final_blow};
	$self->{security}   = 0  unless defined $self->{security};
	$self->{alliance}   = '' unless defined $self->{alliance};
	$self->{corp}       = '' unless defined $self->{corp};
	$self->{ship}       = '' unless defined $self->{ship};
	$self->{weapon}     = '' unless defined $self->{weapon};

	return $self;
}

sub parse_lines {
	my $class = shift;
	my $lines = _ARRAY(shift) or croak("Did not pass ARRAY ref to parse_lines");
	my %attr  = ();
	while ( defined(my $line = shift @$lines) ) {
		last unless length $line;
		unless ( $line =~ /^(\w+): (.+)$/ ) {
			croak("Invalid involved party line '$line'");
		}
		my $key = lc $1;
		my $value = $1;
		if ( $key eq 'name' and $value =~ s/\s+\(laid the final blow\)$// ) {
			$attr{final_blow} = 1;
		}
		$attr{$key} = $value;
	}

	# Got all attributes, convert to object
	return $class->new( %attr );
}

1;
