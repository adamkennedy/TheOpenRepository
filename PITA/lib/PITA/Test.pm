package PITA::Guest;

# A complete abstraction of a Guest

use 5.006;
use strict;
use base 'Process::YAML', 'Process';
use PITA::XML ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.40';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->_init;
	$self;
}

sub _init {
	my $self = shift;

	# Load the Guest XML file
	unless ( $self->filename and -f $self->filename ) {
		Carp::croak('Missing or bad guest xml filename');
	}
	if ( _STRING($self->xml) ) {
		$self->{guest} = PITA::XML::Guest->read($self->guest);
	}
	unless ( _INSTANCE($self->guest, 'PITA::XML::Guest') ) {
		Carp::croak('Missing or invalid guest');
	}

	$self;
}

sub guest {
	$_[0]->{guest};
}

sub discovered {
	$_[0]->guest->discovered;	
}

1;
