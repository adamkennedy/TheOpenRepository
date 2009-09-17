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

#use metaclass (
#	base_class  => 'MooseX::Singleton::Object',
#	metaclass   => 'MooseX::Singleton::Meta::Class',
#	error_class => 'WiX3::Util::Error',
#);
use MooseX::Singleton;
use Params::Util qw( _IDENTIFIER _STRING );
use File::Spec::Functions qw( catdir catpath splitdir splitpath );
use MooseX::Types::Moose qw( Str );
use Perl::Dist::WiX::Directory;
use WiX3::Exceptions;

our $VERSION = '1.090_102';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

with 'WiX3::Role::Traceable';

#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.

has root => (
	is     => 'ro',
	isa    => 'Perl::Dist::WiX::Directory',
	reader => 'get_root',
	handles =>
	  [qw(search_dir get_directory_object _add_directory_recursive)],
	required => 1,
);

has app_dir => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_app_dir',
	required => 1,
);

has app_name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_app_name',
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
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw(
'Parameters incorrect (not a hashref or a hash) for DirectoryTree2'
		);
	}

	my $app_dir = $args{'app_dir'}
	  or PDWiX::Parameter->throw('No app_dir parameter');

	my $root = Perl::Dist::WiX::Directory->new(
		id       => 'TARGETDIR',
		name     => 'SourceDir',
		path     => $app_dir,
		noprefix => 1,
	);

	return {
		root => $root,
		%args
	};
} ## end sub BUILDARGS

sub as_string {
	my $self = shift;

	my $string = $self->get_root()->as_string();

	return $string ne q{} ? $self->get_root()->indent( 4, $string ) : q{};
}


sub initialize_tree {
	my $self = shift;
	my $ver  = shift;

	$self->trace_line( 2, "Initializing directory tree.\n" );

	# Create starting directories.
	my $branch = $self->get_root()->add_directory( {
			id       => 'INSTALLDIR',
			noprefix => 1,
			path     => $self->_get_app_dir(),
		} );
	$self->get_root()->add_directory( {
			id       => 'ProgramMenuFolder',
			noprefix => 1,
		}
	  )->add_directory( {
			id   => 'App_Menu',
			name => $self->_get_app_name(),
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
	) if (5100 <= $ver);
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
	  perl\\site\\lib\\auto
	  perl\\vendor\\lib\\auto\\share\\dist
	  perl\\vendor\\lib\\auto\\share\\module
	  cpan\\sources
	);

	foreach my $dir (@list) {
		$self->add_directory( catdir( $self->_get_app_dir(), $dir ) );
	}

	return $self;
} ## end sub initialize_tree

sub add_directory {
	my $self = shift;
	my $dir  = shift;

	unless ( defined _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::DirectoryTree->add_directory'
		);
	}

	$self->trace_line( 3, "Adding directory with path $dir to tree.\n" );

	# Does the directory already exist?
	# If so, short-circuit.
	return 1
	  if (
		$self->search_dir(
			path_to_find => $dir,
			descend      => 1,
			exact        => 1,
		) );

	my ( $volume, $dirs, undef ) = splitpath( $dir, 1 );
	my @dirs         = splitdir($dirs);
	my $dir_to_add   = pop @dirs;
	my $path_to_find = catdir( $volume, @dirs );

	$self->trace_line( 5,
"  Adding directory recursively: $path_to_find, $dir_to_add to tree.\n"
	);
	my $dir_out =
	  $self->_add_directory_recursive( $path_to_find, $dir_to_add );

	return defined $dir_out ? 1 : 0;
} ## end sub add_directory

sub add_root_directory {
	my $self = shift;
	my $id   = shift;
	my $dir  = shift;

	my $branch = $self->get_directory_object('INSTALLDIR');
	return $branch->add_directories_id( $id, $dir );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::DirectoryTree2 - Base directory tree for Perl::Dist::WiX.

=head1 VERSION

This document describes Perl::Dist::WiX::DirectoryTree2 version 1.090.

=head1 DESCRIPTION

This is an object that establishes a directory tree.

=head1 METHODS

=head2 new

	my $tree = Perl::Dist::WiX::DirectoryTree2->new(
		app_dir => 'C:\strawberry',
		app_name => 'Strawberry Perl'
	);

Creates new directory tree object and creates the 'root' of the tree.

Note that this object is a L<MooseX::Singleton|MooseX::Singleton> object.

=head2 instance

	my $tree = Perl::Dist::WiX::DirectoryTree2->instance();
	
Returns the previously created directory tree. 

=head2 get_root

	my $directory_object = $tree->get_root();
	
Gets the L<Perl::Dist::WiX::Directory|Perl::Dist::WiX::Directory> object at
the root of the tree.
	
=head2 initialize_tree

	$tree->initialize_tree($perl_version);

Adds a basic directory structure to the directory tree object.

=head2 add_directory

	$tree->add_directory($directory);

Adds a directory to the tree, including all directories required along 
the way.
	
=head2 as_string

	print $tree->as_string();
	
Prints out the tree as a series of XML tags.

=head2 get_directory_object

Calls L<Perl::Dist::WiX::Directory's get_directory_object routine|Perl::Dist::WiX::Directory/get_directory_object>
on the root directory with the parameters given.

=head2 search_dir

Calls L<Perl::Dist::WiX::Directory's search_dir routine|Perl::Dist::WiX::Directory/search_dir>
on the root directory with the parameters given.

=head1 DIAGNOSTICS

See Perl::Dist::WiX's L<DIAGNOSTICS section|Perl::Dist::WiX/DIAGNOSTICS> for 
details, as all diagnostics from this module are listed there.

=head1 SUPPORT

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
