package Perl::Dist::WiX::Files::Component;
{
#####################################################################
# Perl::Dist::WiX::Files::Component - Class for a <Component> tag that contains file(s).
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     vars              qw( $VERSION );
use     Object::InsideOut qw(
    Perl::Dist::WiX::Base::Component
    Storable
);
use     Carp              qw( croak    );
use     Params::Util      qw( _STRING  );
require Perl::Dist::WiX::Files::Entry;

use version; $VERSION = qv('0.13_02');
#>>>
#####################################################################
# Accessors:
#   name, filename: Returns the filename parameter passed in to new.

	my @name : Field : Arg(Name => 'filename', Required => 1) : Get(name);

	sub filename { return $_[0]->name; }

#####################################################################
# Constructor for Files::Component
#
# Parameters: [pairs]
#   filename: The name of the file that is being added
#   id: Id parameter to the <Component> tag (generated if not given)
#   guid: Id parameter to the <Component> tag (generated if not given)

	sub _init :Init {
		my $self      = shift;
		my $object_id = ${$self};

		# Check parameters.
		unless ( _STRING( $name[$object_id] ) ) {
			croak('Missing or invalid filename param');
		}

		# Create a GUID if required.
		unless ( defined $self->get_guid() ) {
			$self->set_guid( $self->generate_guid( $name[$object_id] ) );
			my $id = $self->get_guid();
			$id =~ s{-}{_}smg;
			$self->set_component_id($id);
		}

		# Add the entry (Each component contains one entry.)
		$self->add_entry(
			Perl::Dist::WiX::Files::Entry->new(
				name => $name[$object_id],
			) );

		return $self;
	} ## end sub new

#####################################################################
# Main Methods

########################################
# is_file($filename)
# Parameters:
#   $filename: Filename being searched for
# Returns: [boolean]
#   True if this is the object for this filename.

	sub is_file {
		my ( $self, $filename ) = @_;

		# Check parameters.
		unless ( _STRING($filename) ) {
			croak('Missing or invalid filename param');
		}

		return ( $self->filename eq $filename ) ? 1 : 0;
	}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Id attached to this component.

	sub get_component_array {
		my $self = shift;

		return 'C_' . $self->get_component_id;
	}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <Component> tag represented by this object,
#   along with the <File> entry it contains.

	sub as_string {
		my $self = shift;

		# Short-circuit.
		return q{} if ( 0 == scalar @{ $self->get_entries } );

		# Start accumulating XML.
		my $answer = $self->as_start_string();
		$answer .= $self->SUPER::as_string(2);
		$answer .= <<'END_OF_XML';
</Component>
END_OF_XML

		return $answer;
	} ## end sub as_string

}

1;

