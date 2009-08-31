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
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catpath catdir abs2rel splitpath splitdir );
use Params::Util qw( _STRING );

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Directory';

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
			# TODO: Throw an error.
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

sub search_dir {
	my $self = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( @_ % 2 == 0 ) {
		%args = @_ ;
	} else {
#		print "Argument problem\n";
		# Throw error.
	}
	
	# Set defaults for parameters.
	my $path_to_find = _STRING( $args{'path_to_find'} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::Directory->search_dir'
	  );
	my $descend = $args{descend} || 1;
	my $exact   = $args{exact}   || 0;
	my $path    = $self->get_path();
	
#	print "Path problem\n" unless defined $path;
	return undef unless defined $path;

# TODO: Make trace_line work.	
#	$self->trace_line( 3, "Looking for $path_to_find\n" );
#	$self->trace_line( 4, "  in:      $path.\n" );
#	$self->trace_line( 5, "  descend: $descend exact: $exact.\n" );
#print "Looking for $path_to_find\n" ;
#print "  in:      $path.\n" ;
#print "  descend: $descend exact: $exact.\n" ;

	# If we're at the correct path, exit with success!
	if ( ( defined $path ) && ( $path_to_find eq $path ) ) {
#		$self->trace_line( 4, "Found $path.\n" );
#print "Found $path.\n" ;
		return $self;
	}

	# Quick exit if required.
	return undef unless $descend;

	# Do we want to continue searching down this direction?
	my $subset = "$path_to_find\\" =~ m{\A\Q$path\E\\}msx;
	if ( not $subset ) {
#		$self->trace_line( 4, "Not a subset in: $path.\n" );
#		$self->trace_line( 5, "  To find: $path_to_find.\n" );
#print "Not a subset in: $path.\n" ;
#print "  To find: $path_to_find.\n" ;
		return undef;
	}

	# Check each of our branches.
	my @tags = $self->get_child_tags();
	my $answer;
#	print "** Number of child tags: " . scalar @tags . "\n";
	
  TAG:
	foreach my $tag ( @tags ) {
		next TAG unless $tag->isa('Perl::Dist::WiX::Directory');
		
		$answer = $tag->search_dir( \%args );
		if ( defined $answer ) {
			return $answer;
		}
	}

	# If we get here, we did not find a lower directory.
	return $exact ? undef : $self;
}

sub _add_directory_recursive {
	my $self = shift;
	my $path_to_find = shift;
	my $dir_to_add = shift;
	
	# Should not happen, but checking to make sure we bottom out, 
	# rather than going into infinite recursion.
	if (length $path_to_find < 4) {
		return undef;
	}
	
	my $directory = $self->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if (defined $directory) {
		return $directory->add_directory(
			name => $dir_to_add,
			# TODO: Check for other needs.
		);
	} else {
		my ($volume, $dirs, undef) = splitpath($path_to_find, 1);
		my @dirs = splitdir($dirs);
		my $dir_to_add_down = pop @dirs;
		my $path_to_find_down = catpath($volume, catdir(@dirs), undef);
		my $dir = $self->_add_directory_recursive($path_to_find_down, $dir_to_add_down);
		return $dir->add_directory( name => $dir_to_add );
		
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;