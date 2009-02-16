package Perl::Dist::WiX::Base::Component;
{

#####################################################################
# Perl::Dist::WiX::Base::Component - Base class for <Component> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly.
# Use as virtual base class and for "isa" tests only.
#<<<
use 5.006;
use strict;
use warnings;
use vars              qw( $VERSION                      );
use Object::InsideOut qw( Perl::Dist::WiX::Misc :Public );
use Carp              qw( croak                         );
use Params::Util      qw( _CLASSISA _STRING _NONNEGINT  );

use version; $VERSION = qv('0.13_02');
#>>>

#####################################################################
# Attributes:
#   entries: Entries contained in this component.

	my @id : Field : Arg(Name => 'id') : Std(Name => 'component_id', Restricted => 1);
	my @guid : Field : Arg(guid) : Std(Name => 'guid', Restricted => 1);
	my @entries : Field : Get(Name => 'get_entries', Restricted => 1);
    
    sub get_entries_count {
        my $self = shift;
        return scalar @{ $self->get_entries };
    }

#####################################################################
# Constructors for Base::Component
#
# Parameters: [pairs]
#   id: Id parameter to the <Component> tag
#   guid: Guid parameter to the <Component> tag (generated if not given)

	sub _init : Init {
		my $self = shift;

		$entries[ ${$self} ] = [];

		return;
	}

#####################################################################
# Main Methods

########################################
# add_entry($entry)
# Parameters:
#   $entry: Entry object being added. Must be a subclass of
#   Perl::Dist::WiX::Base::Entry
# Returns:
#   Object being called. (chainable)

	sub add_entry {
		my ( $self, $entry ) = @_;
		my $object_id = ${$self};

		unless ( _CLASSISA( ref $entry, 'Perl::Dist::WiX::Base::Entry' ) ) {
			croak 'Not adding a valid component';
		}

		# getting the number of items in the array
		# referred to by $self->{entries}
		my $i = scalar @{ $entries[$object_id] };

		# Adding entry.
		$entries[$object_id]->[$i] = $entry;

		return $self;
	} ## end sub add_entry

########################################
# create_guid_from_id
# Parameters:
#   None
# Action:
#   Creates a GUID from the sitename and id object variables and stores it
#   in the object.
# Returns:
#   Object being called. (chainable)

	sub create_guid_from_id {
		my $self      = shift;
		my $object_id = ${$self};

		# Check parameters.
		unless ( _STRING( $id[$object_id] ) ) {
			croak 'Missing or invalid id param - cannot generate GUID '
			  . 'without one';
		}

		# Generate the GUID...
		$guid[$object_id] = $self->generate_guid( $id[$object_id] );

		return $self;
	} ## end sub create_guid_from_id

########################################
# as_string($spaces)
# Parameters:
#   $spaces: Number of spaces to indent string returned.
# Returns:
#   String representation of entries contained by this object.

	sub as_string {
		my ( $self, $spaces ) = @_;
		my $object_id = ${$self};
		my $string;
		my $s;

		# Short-circuit
		return q{} if ( scalar @{ $entries[$object_id] } == 0 );

		unless ( _STRING( $id[$object_id] ) ) {
			croak('Missing or invalid id param');
		}

		unless ( _STRING( $guid[$object_id] ) ) {
			$guid[$object_id] = generate_guid($id[$object_id]);
		}
                
		# Check parameters.
		unless ( defined _NONNEGINT($spaces) ) {
			croak 'Calling as_spaces improperly '
			  . '(most likely, not calling derived method)';
		}

		# Stringify each entry and indent it.
		my $count = scalar @{ $entries[$object_id] };
		foreach my $i ( 0 .. $count - 1 ) {
			$s = $entries[$object_id]->[$i]->as_string;
			$string .= $self->indent( $spaces, $s );
			$string .= "\n";
		}

		return $string;
	} ## end sub as_string

########################################
# as_start_string()
# Parameters:
#   none.
# Returns:
#   String representation of attributes of this object.

	sub as_start_string {
		my $self      = shift;
		my $object_id = ${$self};

		return <<"END_OF_XML";
<Component Id='C_$id[$object_id]' Guid='$guid[$object_id]'>
END_OF_XML

	}

}

1;
