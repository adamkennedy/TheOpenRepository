package XML::WiX3::Classes::FilesFragment;

####################################################################
# Perl::Dist::WiX::Files - <Fragment> tag that contains
# <DirectoryRef> tags
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                 );
use     Params::Util
	qw( _IDENTIFIER _STRING _INSTANCE _ARRAY0 );
use     File::Spec::Functions qw( splitpath catpath catdir );
use     Readonly              qw( Readonly                 );
require Perl::Dist::WiX::DirectoryTree;
require Perl::Dist::WiX::Files::DirectoryRef;

use version; $VERSION = version->new('0.003')->numify;
#>>>

with 'XML::WiX3::Classes::Role::Tag';
with 'XML::WiX3::Classes::Role::Fragment';

Readonly my $TREE_CLASS => 'Perl::Dist::WiX::DirectoryTree';

#####################################################################
# Accessors:
#   see new.

has directory_tree {
	is => ro,
	isa => 'Perl::Dist::WiX::DirectoryTree',
	getter => '_get_directory_tree';
}

#####################################################################
# Constructor for Files
#
# Parameters: [pairs]
#   directory_tree: [Wix::DirectoryTree object] The initial directory tree.

########################################
# add_files(@files)
# Parameters:
#   @files: List of filenames to add.
# Returns:
#   Object being operated on (chainable).

sub add_files {
	my ( $self, @files ) = @_;

# Each file could be a directory or have a newline, so fix that and add the files.
	foreach my $file (@files) {
		chomp $file;
		next if not -f $file;
		if ( not defined $self->add_file($file) ) {
			XWObj->throw("Could not add $file");
		}
	}

	return $self;
} ## end sub add_files

########################################
# add_file($file)
# Parameters:
#   $file: Filename to add.
# Returns:
#   Files::Component object added or undef.

sub add_file {
	my ( $self, $file ) = @_;
	my ( $directory_obj, $directory_ref_obj, $file_obj, $subpath ) =
	  ( undef, undef, undef, undef );

	# Check parameters.
	unless ( _STRING($file) ) {
		PDWiX::Parameter->throw(
			parameter => 'file',
			where     => '::Files->new'
		);
	}

	# Do not add .AAA files.
	return undef if ( $file =~ m{\.AAA\z}ms );

	# Get the file path.
	my ( $vol, $dirs, $filename ) = splitpath($file);
	my $path = catdir( $vol, $dirs );

	$self->trace_line( 3, "Adding file $file.\n" );

	# Remove ending backslash.
	if ( substr( $path, -1 ) eq q{\\} ) {
		$path = substr $path, 0, -1;
	}

# 1. Is there a Directory{Ref} for this path in this object?

# Check if we have a Directory{Ref} directly contained with the appropriate path.
	$directory_ref_obj = $self->_search_refs(
		path_to_find => $path,
		descend      => 1,
		exact        => 1
	);
	if ( defined $directory_ref_obj ) {

		# Yes, we do. Add the file to this Directory{Ref}.
		$self->trace_line( 4,
			"Stage 1 - Adding file to Directory{Ref} for $path.\n" );
		$file_obj = $directory_ref_obj->add_file( filename => $file, );
		return $file_obj;
	}

# 2. Is there another Directory to create a reference of?
	$self->trace_line( 5, "Stage 1 - Unsuccessful.\n" );

	# Check if we have a Directory in the tree to take a reference of.
	$directory_obj = $self->_get_directory_tree()->search_dir(
		path_to_find => $path,
		descend      => 1,
		exact        => 1
	);
	if ( defined $directory_obj ) {

		# Make a DirectoryRef, and attach it.
		$subpath = $directory_obj->get_path;
		$self->trace_line( 4,
			" Stage 2 - Creating DirectoryRef at $subpath.\n" );
		$directory_ref_obj =
		  Perl::Dist::WiX::Files::DirectoryRef->new(
			directory_object => $directory_obj, );
		$self->add_component($directory_ref_obj);

		$self->trace_line( 5, "  Adding file $file.\n" );

		# Add the file.
		$file_obj = $directory_ref_obj->add_file( filename => $file, );
		return $file_obj;
	} ## end if ( defined $directory_obj)

# 3. Check for a higher directory in the directory tree and in the .
	$self->trace_line( 5, "Stage 2 - Unsuccessful.\n" );

	# Check if we have a Directory in the tree to take a reference of.
	$directory_obj = $self->_get_directory_tree()->search_dir(
		path_to_find => $path,
		descend      => 1,
		exact        => 0
	);

	# Check if we have a DirectoryRef in the object to refer to.
	$directory_ref_obj = $self->_search_refs(
		path_to_find => $path,
		descend      => 1,
		exact        => 0
	);

	# Which one do we want to use?
	my $use = -1;

 # Determine which one of these 2 to use
 # $use = 1 means use $directory_obj, $use = 0 means use $directory_ref_obj.
	if ( not defined $directory_obj ) {
		if ( not defined $directory_ref_obj ) {
			$use = -1;
		} else {
			$use = 0;
		}
	} else {
		if ( not defined $directory_ref_obj ) {
			$use = 1;
		} else {
			if ( $directory_obj->get_path eq $directory_ref_obj->get_path )
			{

				# Use directory_ref if the paths found are equal.
				$use = 0;
			} else {
				$use = $directory_obj->is_child_of($directory_ref_obj);
			}
		}
	} ## end else [ if ( not defined $directory_obj)

	# Now use the one that's "lower" in the directory tree.
	if ( $use == 0 ) {

		# Using $directory_ref_obj [from this object]
		$subpath = $directory_ref_obj->get_path;
		$self->trace_line( 5,
			    'Stage 3a - Creating Directory within '
			  . "Directory{Ref} for $subpath.\n" );
		$self->trace_line( 5, "  Adding path $path.\n" );
		$self->trace_line( 5, "  Adding file $file.\n" );

		# Create the directory objects and add the file.
		$directory_obj = $directory_ref_obj->add_directory_path($path);
		$file_obj = $directory_obj->add_file( filename => $file, );
		return $file_obj;
	} elsif ( $use == 1 ) {

		# Using $directory_obj [from DirectoryTree object]
		$subpath = $directory_obj->get_path;
		$self->trace_line( 5,
			    'Stage 3b - Creating Directory within '
			  . "Directory for $subpath.\n" );
		$self->trace_line( 5, "  Adding path $path.\n" );
		$self->trace_line( 5, "  Adding file $file.\n" );

		# Create the directory objects and add the file.
		$directory_ref_obj =
		  Perl::Dist::WiX::Files::DirectoryRef->new(
			directory_object => $directory_obj, );
		$self->add_component($directory_ref_obj);
		$directory_obj = $directory_ref_obj->add_directory_path($path);
		$file_obj = $directory_obj->add_file( filename => $file, );
		return $file_obj;
	} else {
		$self->trace_line( 5, "Stage 3 - Unsuccessful.\n" );

		# Completely unsuccessful.
		return undef;
	}
} ## end sub add_file

# Gets a list of paths "above" the currect directory specified in
# $volume and $dirs.

sub _get_possible_paths {
	my ( $self, $volume, $dirs ) = @_;

	# Get our list of directories.
	my @directories = splitdir($dirs);

	# Get rid of empty entries at the beginning or end.
	while ( $directories[-1] eq q{} ) {
		pop @directories;
	}
	while ( $directories[0] eq q{} ) {
		shift @directories;
	}

	my $dir;
	my @answers;

	# Until we get to the last level...
	while ( $#directories > 1 ) {

		# Remove a level and create its path.
		pop @directories;
		$dir = catdir( $volume, catdir(@directories) );

		# Add it to the answers list.
		push @answers, $dir;
	}

	return @answers;
} ## end sub _get_possible_paths

# Searches our contained DirectoryRefs for a path.

sub _search_refs {
	my $self       = shift;
	my $params_ref = {@_};

	# Set defaults for parameters.
	my $path_to_find = $params_ref->{path_to_find}
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::Files->_search_refs'
	  );
	my $descend = $params_ref->{descend} || 1;
	my $exact   = $params_ref->{exact}   || 0;

	my $answer = undef;

	# How many descendants do we have?
	my $count = scalar @{ $self->get_components };

	# Pass the search down to each our descendants.
	foreach my $i ( 0 .. $count - 1 ) {
		$answer = $self->get_components->[$i]->search_dir(
			path_to_find => $path_to_find,
			descend      => $descend,
			exact        => $exact,
		);

		# Exit if one of our descendants is successful.
		return $answer if defined $answer;
	}

	# We were unsuccessful.
	return undef;
} ## end sub _search_refs

########################################
# search_file($filename)
# Parameters:
#   $filename: Filename to search for.
# Returns:
#   Files::Component object found or undef.

sub search_file {
	my ( $self, $filename ) = @_;
	my $answer = undef;

	# Check parameters.
	unless ( _STRING($filename) ) {
		PDWiX::Parameter->throw(
			parameter => 'filename',
			where     => '::Files->search_file'
		);
	}

	# How many descendants do we have?
	my $count = scalar @{ $self->get_components };

	# Pass the search down to each our descendants.
	foreach my $i ( 0 .. $count - 1 ) {
		$answer = $self->get_components->[$i]->search_file($filename);

		# Exit if one of our descendants is successful.
		return $answer if defined $answer;
	}

	# We were unsuccessful.
	return undef;
} ## end sub search_file

########################################
# check_duplicates($files_ref)
# Parameters:
#   $files_ref: arrayref of filenames to remove from this object.
# Returns:
#   Object being operated on (chainable).
# Action:
#   Removes filenames listed in $files_ref from this object if they're in it.

sub check_duplicates {
	my ( $self, $files_ref ) = @_;
	my $answer;
	my ( $object, $index, $pathname_fixed );

	# Check parameters.
	unless ( _ARRAY0($files_ref) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_ref',
			where     => '::Files->check_duplicates'
		);
	}

	# For each file in the list...
	foreach my $pathname ( @{$files_ref} ) {

		# For a .AAA file, find the original file instead.
		if ( $pathname =~ m{\.AAA\z}ms ) {
			$pathname_fixed = substr $pathname, 0, -4;
		} else {
			$pathname_fixed = $pathname;
		}

		# Try and find the file.
		$answer = $self->search_file($pathname_fixed);

		# Delete the original file if found.
		if ( defined $answer ) {
			( $object, $index ) = @{$answer};
			$self->trace_line( 4,
				    "Deleting reference $index at "
				  . $object->get_path
				  . "\n" );
			$object->delete_filenum($index);
		}
	} ## end foreach my $pathname ( @{$files_ref...

	return $self;
} ## end sub check_duplicates

########################################
# get_component_array
# Parameters:
#   None.
# Returns:
#   Array of the Id attributes of the components within this object.

sub get_component_array {
	my $self = shift;
	my @answer;

	# Get the array for each descendant.
	my $count = scalar @{ $self->get_components };
	foreach my $i ( 0 .. $count - 1 ) {
		push @answer, $self->get_components->[$i]->get_component_array;
	}

	return @answer;
} ## end sub get_component_array

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing fragment defined by this object
#   and DirectoryRef objects contained in this object.

sub as_string {
	my $self = shift;
	my ( $string, $s );

	my $components = $self->get_components;

	# How many descendants do we have?
	my $count = scalar @{$components};

	# Short circuit.
	if ( $count == 0 ) {
		my $id = $self->get_fragment_id();
		$self->trace_line( 2, "No components in fragment $id" );
		return q{};
	}

	my $id = $self->get_fragment_id();

	# Start our fragment.
	$string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$id'>
EOF

	# Get the string for each descendant.
	foreach my $i ( 0 .. $count - 1 ) {
		$s = $components->[$i]->as_string;
		chomp $s;
		if ( $s ne q{} ) {
			$string .= $self->indent( 4, $s );
			$string .= "\n";
		}
	}

	# End the fragment.
	$string .= <<'EOF';
  </Fragment>
</Wix>
EOF
	return $string;
} ## end sub as_string

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

XML::WiX3::Classes::Exceptions - Exceptions used in XML::WiX3::Objects.

=head1 VERSION

This document describes XML::WiX3::Classes::Exceptions version 0.003

=head1 SYNOPSIS

    eval { new XML::WiX3::Classes::RegistryKey() };
	if ( my $e = XWC::Exception::Parameter->caught() ) {

		my $parameter = $e->parameter;
		die "Bad Parameter $e passed in.";
	
	}
  
=head1 DESCRIPTION

This module defines the exceptions used by XML::WiX3::Classes.  All 
exceptions used are L<Exception::Class> objects.

Note that uncaught exceptions will try to print out an understandable
error message, and if a high enough tracelevel is available, will print
out a stack trace, as well.

=head1 INTERFACE 

=head2 ::Parameter

Parameter exceptions will always print a stack trace.

=head3 $e->parameter()

The name of the parameter with the error.

=head3 $e->info()

Information about how the parameter was bad.

=head3 $e->where()

Information about what routine had the bad parameter.

=back

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

This module provides the error diagnostics for the XML::WiX3::Objects 
distribution.  It has no diagnostics of its own.

=head1 CONFIGURATION AND ENVIRONMENT
  
XML::WiX3::Classes::Exceptions requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Exception::Class> version 1.22 or later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<Exception::Class>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

