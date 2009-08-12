package                                # Hide from PAUSE
  WiX3::XML::GeneratesGUID::Object;

#<<<
use     5.006;
use		MooseX::Singleton;
use     vars                   qw( $VERSION      );
use     Data::UUID             qw( NameSpace_DNS );
use     WiX3::Types            qw( Host          );
require WiX3::XML::Exceptions;

use version; $VERSION = version->new('0.003')->numify;
#>>>


#####################################################################
# Attributes

with 'WiX3::Role::Traceable';

has _sitename => (
	is      => 'ro',
	isa     => Host,
	reader  => '_get_sitename',
	default => q{www.perl.invalid},
);

has _guidgen => (
	is       => 'ro',
	isa      => 'Data::UUID',
	reader   => '_get_guidgen',
	init_arg => undef,
	default  => sub {
		return Data::UUID->new();
	},
);

has _sitename_guid => (
	is       => 'ro',
	isa      => 'Str',
	reader   => '_get_sitename_guid',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;

		my $guidgen = $self->_get_guidgen();

		my $guid =
		  $guidgen->create_from_name( Data::UUID::NameSpace_DNS,
			$self->_get_sitename() );

		$self->trace_line( 5,
			'Generated site GUID: ' . $guidgen->to_string($guid) . "\n" );

		return $guid;
	},
);

#####################################################################
# Accessors

#####################################################################
# Main Methods

########################################
# generate_guid($id)
# Parameters:
#   $id: ID to create a GUID for.
# Returns:
#   The GUID generated.

sub generate_guid {
	my ( $self, $id ) = @_;

	#... then use it to create a GUID out of the filename.
	return
	  uc $self->_get_guidgen()
	  ->create_from_name_str( $self->_get_sitename_guid(), $id );

}

__PACKAGE__->meta->make_immutable;
no MooseX::Singleton;

1;
