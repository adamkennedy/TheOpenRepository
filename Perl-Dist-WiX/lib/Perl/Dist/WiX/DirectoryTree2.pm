package Perl::Dist::WiX::DirectoryTree2;

#####################################################################
# Perl::Dist::WiX::DirectoryTree2 - Class containing initial tree of
#   <Directory> tag objects.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use MooseX::Singleton;
use Params::Util          qw( _IDENTIFIER _STRING            );
use File::Spec::Functions qw( catdir                         );
use MooseX::Types::Moose  qw( Str                            );
use Perl::Dist::WiX::Directory;
use WiX3::Exceptions;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'WiX3::Role::Traceable';

#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.

has root => (
	is => 'ro',
	isa => 'WiX3::XML::Directory',
	reader => 'get_root',
	required => 1,
);

has app_dir => (
	is => 'ro',
	isa => Str,
	reader => 'get_app_dir',
	required => 1,
);

has app_name => (
	is => 'ro',
	isa => Str,
	reader => 'get_app_name',
	required => 1,
);

#####################################################################
# Constructor for DirectoryTree
#
# Parameters: [pairs]

sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{$_[0]};
	} elsif ( 0 == @_ % 2 ) {
		%args = ( @_ );
	} else {
		# TODO: Throw an error.
	}

	my $app_dir = $args{'app_dir'};

	my $root = Perl::Dist::WiX::Directory->new( 
		id       => 'TARGETDIR', 
		name     => 'SourceDir',
		path     => $app_dir,
		noprefix => 1,
	);
	
	return { root => $root, %args }; 
}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of the <Directory> tags this object contains.

sub as_string {
	my $self = shift;

	my $string = $self->get_root()->as_string(1);

	return $string ne q{} ? $self->get_root()->indent( 4, $string ) : q{};
}


sub initialize_tree {
	my $self = shift;
	my $ver = shift;
	
	$self->trace_line( 2, "Initializing directory tree.\n" );

	# Create starting directories.
	my $branch = $self->get_root->add_directory( {
			id       => 'INSTALLDIR',
			noprefix => 1,
			path     => $self->get_app_dir(),
		} );
	$self->get_root->add_directory( {
			id       => 'ProgramMenuFolder',
			noprefix => 1,
		}
	  )->add_directory( {
			id      => 'App_Menu',
			name    => $self->get_app_name(),
	} );

#<<<
	$branch->add_directories_id(
		'Perl',      'perl',
		'Toolchain', 'c',
		'License',   'licenses',
		'Cpan',      'cpan',
		'Win32',     'win32',
	);
	$branch->add_directories_id(
		'Cpanplus',  'cpanplus',
	) if (5100 >= $ver);
#>>>
	
	return $self;
}

sub get_directory_object {
	my $self = shift;
	my $id = shift;
	
	return $self->get_root()->get_directory_object($id);
}

# We still need to get the routines below written.

sub search_dir {
	WiX3::Exception::Unimplemented->throw();
	
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

########################################
# search_dir($path)
# Parameters: [pairs]
#   path_to_find: Path being searched for.
#   descend: 1 if can descend to lower levels, [default]
#            0 if has to be on this level.
#   exact:   1 if has to be equal,
#            0 if equal or subset. [default]
# Returns:
#   Directory object representing $path or undef.

sub search_dir {
	my $self       = shift;
	my $params_ref = {@_};

	# Set defaults for parameters.
	$self->trace_line( 5,
		    "\$self: $self\n$params_ref: $params_ref\n"
		  . "path_to_find: $params_ref->{path_to_find}\n" );
	my $path_to_find = _STRING( $params_ref->{path_to_find} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::DirectoryTree->search_dir'
	  );
	my $descend = $params_ref->{descend} || 1;
	my $exact   = $params_ref->{exact}   || 0;

	return $self->root->search_dir(
		path_to_find => $path_to_find,
		descend      => $descend,
		exact        => $exact,
	);
} ## end sub search_dir

########################################
# add_root_directory($id, $dir)

sub add_root_directory {
	my ( $self, $id, $dir ) = @_;

	unless ( defined _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::DirectoryTree->add_root_directory'
		);
	}

	unless ( defined _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::DirectoryTree->add_root_directory'
		);
	}

	my $path = $self->app_dir;

	$self->trace_line( 5, "Path: $path\n" );

	return $self->search_dir(
		path_to_find => $path,
		descend      => 0,
		exact        => 1,
	  )->add_directory( {
			id   => $id,
			name => $dir,
			path => catdir( $path, $dir ) } );
} ## end sub add_root_directory


1;
