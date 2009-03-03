package Perl::Dist::WiX::Base::Fragment;

#####################################################################
# Perl::Dist::WiX::Base::Fragment - Base class for <Fragment> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly.
# Use as virtual base class and for "isa" tests only.
#
#<<<
use 5.006;
use strict;
use warnings;
use vars              qw( $VERSION                               );
use Readonly          qw( Readonly                               );
use Object::InsideOut qw( Perl::Dist::WiX::Misc :Public Storable );
use Params::Util      qw( _INSTANCE _STRING                      );

use version; $VERSION = qv('0.14');

Readonly my $COMPONENT_CLASS => 'Perl::Dist::WiX::Base::Component';

#>>>
#####################################################################
# Accessors:
#   get_id: Returns the id parameter passed in to new.
#   get_directory: Returns the directory parameter passed in to new.
#   get_components: Returns the components contained in this fragment.

## no critic 'ProhibitUnusedVariables'
my @id : Field : Arg(id) :
  Std(Name => 'fragment_id', Permission => 'Restrict(Perl::Dist::WiX::Installer)');
my @directory : Field : Arg(Name => 'directory', Default => 'TARGETDIR') :
  Std(Name => 'directory_id', Restricted => 1);
my @components : Field : Name(components) :
  Get(Name => 'get_components', Restricted => 1);

#####################################################################
# Constructor for Base::Fragment
#
# Parameters: [pairs]
#   id: Id parameter to the <Fragment> tag (required)
#   directory: Id parameter to the <DirectoryRef> tag  within this fragment.

sub _init : Init {
	my $self = shift;

	unless ( _STRING( $self->get_directory_id ) ) {
		PDWiX::Parameter->throw(parameter => 'directory', where => 'Perl::Dist::WiX::Base::Fragment->new');
	}
	unless ( _STRING( $self->get_fragment_id ) ) {
		PDWiX::Parameter->throw(parameter => 'id', where => 'Perl::Dist::WiX::Base::Fragment->new');
	}

	# Initialize components arrayref.
	$components[ ${$self} ] = [];

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# add_component($component)
# Parameters:
#   $component: Component object being added. Must be a subclass of
#   Perl::Dist::WiX::Base::Component
# Returns:
#   Object being called. (chainable)

sub add_component {
	my ( $self, $component ) = @_;

	# Check parameters.
	unless ( _INSTANCE( $component, $COMPONENT_CLASS ) ) {
		PDWiX::Parameter->throw(parameter => 'component', where => 'Perl::Dist::WiX::Base::Fragment->add_component');
	}

	# Adding component to the list.
	my $components = $self->get_components;
	my $i          = scalar @{$components};
	$components->[$i] = $component;

	return $self;
} ## end sub add_component

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <Fragment> and <DirectoryRef> tags represented
#   by this object, along with the components it contains.

sub as_string {
	my $self       = shift;
	my $components = $self->get_components;
	my $object_id  = ${$self};
	my $string;
	my $s;

	# Short-circuit.
	return q{} if ( 0 == scalar @{$components} );

	# Start with XML header and opening tags.
	$string = <<"END_OF_XML";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$id[$object_id]'>
    <DirectoryRef Id='$directory[$object_id]'>
END_OF_XML

	# Stringify the components we contain.
	my $count = scalar @{$components};
	foreach my $i ( 0 .. $count - 1 ) {
		$s = $components->[$i]->as_string;
		chomp $s;
		$string .= $self->indent( 6, $s );
		$string .= "\n";
	}

	# Finish up.
	$string .= <<'END_OF_XML';
    </DirectoryRef>
  </Fragment>
</Wix>
END_OF_XML

	return $string;
} ## end sub as_string

1;
