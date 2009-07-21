package PITA::XML::File;

# A PITA::XML class that represents an file resource for a Guest

use strict;
use base 'PITA::XML::Storable';
use Data::Digest ();
use Params::Util '_INSTANCE',
                 '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.41';
}

sub xml_entity { 'file' }






#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# The file name is required
	unless ( _STRING($self->filename) ) {
		Carp::croak('Missing or invalid filename');
	}

	# The resource descriptor is optional
	if ( exists $self->{resource} ) {
		unless ( _STRING($self->{resource}) ) {
			Carp::croak('Cannot provide a null resource type');
		}
	}

	# The digest is optional
	if ( exists $self->{digest} ) {
		eval { $self->{digest} = $self->_DIGEST($self->{digest}) };
		Carp::croak("Missing or invalid digest") if $@;
	}

	$self;
}

sub filename {
	$_[0]->{filename};
}

sub resource {
	$_[0]->{resource};
}

sub digest {
	$_[0]->{digest};
}





#####################################################################
# Main Methods






#####################################################################
# Support Methods

sub _DIGEST {
	_INSTANCE($_[1], 'Data::Digest') ? $_[1] : Data::Digest->new($_[1]);
}

1;
