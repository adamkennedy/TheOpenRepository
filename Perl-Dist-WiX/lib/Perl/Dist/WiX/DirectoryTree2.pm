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
use metaclass (
	base_class  => 'MooseX::Singleton::Object',
	metaclass   => 'MooseX::Singleton::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use MooseX::Singleton;
use Params::Util          qw( _IDENTIFIER _STRING );
use File::Spec::Functions qw( catdir catpath splitdir splitpath );
use MooseX::Types::Moose  qw( Str );
use Perl::Dist::WiX::Directory;
use WiX3::Exceptions;

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

with 'WiX3::Role::Traceable';

#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.

has root => (
	is => 'ro',
	isa => 'Perl::Dist::WiX::Directory',
	reader => 'get_root',
	handles => [qw(search_dir get_directory_object _add_directory_recursive)],
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
		PDWiX->throw('Parameters incorrect (not a hashref or a hash) for DirectoryTree2');
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
	
	my @list = qw(
		c\\bin
		c\\include
		c\\lib
		c\\libexec
		c\\mingw32
		c\\share
		perl\\bin
		perl\\lib\\auto
		perl\\site\\lib\\auto\\share\\dist
		perl\\site\\lib\\auto\\share\\module
		perl\\vendor\\lib\\auto\\share\\dist
		perl\\vendor\\lib\\auto\\share\\module
		cpan\\sources
	);
	
	foreach my $dir (@list) {
		$self->add_directory( catdir( $self->get_app_dir(), $dir ) );
	}
	
	return $self;
}

sub add_directory {
	my $self = shift;
	my $dir = shift;
	
	$self->trace_line(3, "Adding directory with path $dir to tree.\n");
	
	unless ( defined _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::DirectoryTree->add_directory'
		);
	}

	# Does the directory already exist?
	# If so, short-circuit.
	return 1 if ($self->search_dir(
		path_to_find => $dir,
		descend      => 1,
		exact        => 1,
	) );

	my ($volume, $dirs, undef) = splitpath($dir, 1);
	my @dirs = splitdir($dirs);
	my $dir_to_add = pop @dirs;
	my $path_to_find = catpath($volume, catdir(@dirs), undef);
	
	my $dir_out = $self->_add_directory_recursive($path_to_find, $dir_to_add);

	return defined $dir_out ? 1 : 0;
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

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
