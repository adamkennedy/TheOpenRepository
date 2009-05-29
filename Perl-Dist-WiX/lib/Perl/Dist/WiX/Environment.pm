package Perl::Dist::WiX::Environment;

####################################################################
# Perl::Dist::WiX::Environment - Fragment & Component that contains
#  <Environment> tags
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.008001;
use     strict;
use     warnings;
use     vars              qw( $VERSION       );
use     Object::InsideOut qw(
	Perl::Dist::WiX::Base::Fragment
	Perl::Dist::WiX::Base::Component
	Storable
);
use     Params::Util      qw( _IDENTIFIER    );
require Perl::Dist::WiX::EnvironmentEntry;

use version; $VERSION = version->new('0.183')->numify;
#>>>
#####################################################################
# Accessors:

#####################################################################
# Constructor for Environment
#
# Parameters: [pairs]

sub _pre_init : PreInit {
	my ( $self, $args ) = @_;

	# Apply defaults
	$args->{id} ||= 'Environment';

	return;
}

sub _init : Init {
	my $self = shift;

	# Check parameters.
	unless ( _IDENTIFIER( $self->get_component_id() ) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Environment->new'
		);
	}

	# Make a GUID for as_string to use.
	$self->create_guid_from_id();

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

sub search_file {
	return undef;
}

sub check_duplicates {
	return undef;
}

########################################
# add_entry(...)
# Parameters:
#   Passed to EnvironmentEntry->new.
# Returns:
#   Object being called. (chainable)

sub add_entry {
	my $self = shift;

	my $i = scalar @{ $self->get_entries };
	$self->get_entries->[$i] = Perl::Dist::WiX::EnvironmentEntry->new(@_);

	return $self;
}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Id attached to the contained component.

sub get_component_array {
	my $self = shift;

	return $self->get_component_id;
}

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Fragment> and <Component> tags defined by this object
#   and <Environment> tags defined by objects contained in this object.

sub as_string {
	my ($self) = shift;

	# getting the number of entries.
	my $count = scalar @{ $self->get_entries(); };
	return q{} if ( $count == 0 );

	my $string;
	my $s;
	my $id = $self->get_component_id();

	$string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$id'>
    <DirectoryRef Id='TARGETDIR'>
EOF

	$string .= $self->indent( 6, $self->as_start_string() );
	$string .= "\n";

	foreach my $i ( 0 .. $count - 1 ) {
		$s = $self->get_entries->[$i]->as_string;
		$string .= $self->indent( 6, $s );
		$string .= "\n";
	}

	$string .= <<'EOF';
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

	return $string;
} ## end sub as_string

1;
