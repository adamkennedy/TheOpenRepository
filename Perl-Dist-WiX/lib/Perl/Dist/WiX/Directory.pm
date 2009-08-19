package Perl::Dist::WiX::Directory;

#####################################################################
# Perl::Dist::WiX::Directory - Extends <Directory> tags to make them  
# easily searchable.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.008001;
use Moose;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Directory';

sub add_directory {
	my $self = shift;
	
	my $new_dir = Perl::Dist::WiX::Directory->new(@_);
	$self->add_child_tag($new_dir);

	return $new_dir;
}

########################################
# add_directories_id(($id, $name)...)
# Parameters: [repeatable in pairs]
#   $id:   ID of directory object to create.
#   $name: Name of directory to create object for.
# Returns:
#   Object being operated on. (chainable)

sub add_directories_id {
	my ( $self, @params ) = @_;
	
	# We need id, name pairs passed in.
	if ( @params % 2 != 0 )
	{              
		PDWiX->throw(
			'Internal Error: Odd number of parameters to add_directories_id'
		);
	}

	# Add each individual id and name.
	my ( $id, $name );
	while ( $#params > 0 ) {
		$id   = shift @params;
		$name = shift @params;
		if ( $name =~ m{\\}ms ) {
			$self->add_directory( {
					id   => $id,
					path => $name,
				} );
		} else {
			$self->add_directory( {
					id   => $id,
					path => $self->get_path() . q{\\} . $name,
					name => $name,
				} );
		}
	} ## end while ( $#params > 0 )

	return $self;
} ## end sub add_directories_id

sub get_directory_object {
	my $self = shift;
	my $id = shift;
	
	my $self_id = $self->get_directory_id();
	
	return $self if ($id eq $self_id);
	my $return;
	
  SUBDIRECTORY:
	foreach my $object ($self->get_child_tags()) {
		next SUBDIRECTORY if not $object->isa('Perl::Dist::WiX::Directory');
		$return = $object->get_directory_object($id);
		return $return if defined $return;
	}
	
	return undef;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;