package Perl::Dist::WiX::Tag::DirectoryRef;

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catdir abs2rel );
use Params::Util qw( _STRING _INSTANCE );
require Perl::Dist::WiX::Tag::Directory;

our $VERSION = '1.102_101';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::DirectoryRef';

sub get_directory_object {
	my $self = shift;
	my $id   = shift;

	my $self_id = $self->get_directory_id();

	return $self if ( $id eq $self_id );
	my $return;

  SUBDIRECTORY:
	foreach my $object ( $self->get_child_tags() ) {
		next SUBDIRECTORY
		  if not _INSTANCE( $object, 'Perl::Dist::WiX::Tag::Directory' );
		$return = $object->get_directory_object($id);
		return $return if defined $return;
	}

	## no critic (ProhibitExplicitReturnUndef)
	return undef;
} ## end sub get_directory_object



sub search_dir {
	## no critic (ProhibitExplicitReturnUndef)
	my $self = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( @_ % 2 == 0 ) {
		%args = @_;
	} else {

		PDWiX->throw(
			'Parameters passed to search_dir not a hash or hashref.');
	}

	# Set defaults for parameters.
	my $path_to_find = _STRING( $args{'path_to_find'} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::DirectoryRef->search_dir'
	  );
	my $descend = $args{descend} || 1;
	my $exact   = $args{exact}   || 0;
	my $path    = $self->get_path();

	return undef unless defined $path;

#	$self->trace_line( 3, "Looking for $path_to_find\n" );
#	$self->trace_line( 4, "  in:      $path.\n" );
#	$self->trace_line( 5, "  descend: $descend exact: $exact.\n" );

	# If we're at the correct path, exit with success!
	if ( ( defined $path ) && ( $path_to_find eq $path ) ) {

#		$self->trace_line( 4, "Found $path.\n" );
		return $self;
	}

	# Quick exit if required.
	return undef unless $descend;

	# Do we want to continue searching down this direction?
	my $subset = "$path_to_find\\" =~ m{\A\Q$path\E\\}msx;
	if ( not $subset ) {

#		$self->trace_line( 4, "Not a subset in: $path.\n" );
#		$self->trace_line( 5, "  To find: $path_to_find.\n" );
		return undef;
	}

	# Check each of our branches.
	my @tags = $self->get_child_tags();
	my $answer;

  TAG:
	foreach my $tag (@tags) {
		next TAG unless $tag->isa('Perl::Dist::WiX::Tag::Directory');

		my $x = ref $tag;
		my $y = $tag->get_path();

		$answer = $tag->search_dir( \%args );
		if ( defined $answer ) {
			return $answer;
		}
	}

	# If we get here, we did not find a lower directory.
	return $exact ? undef : $self;
} ## end sub search_dir



sub _add_directory_recursive {
	my $self         = shift;
	my $path_to_find = shift;
	my $dir_to_add   = shift;

	# Should not happen, but checking to make sure we bottom out,
	# rather than going into infinite recursion.
	if ( length $path_to_find < 4 ) {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}

	my $directory = $self->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if ( defined $directory ) {
		return $directory->add_directory(
			parent => $directory,
			name   => $dir_to_add,

			# TODO: Check for other needs.
		);
	} else {
		my ( $volume, $dirs, undef ) = splitpath( $path_to_find, 1 );
		my @dirs              = splitdir($dirs);
		my $dir_to_add_down   = pop @dirs;
		my $path_to_find_down = catpath( $volume, catdir(@dirs), undef );
		my $dir =
		  $self->_add_directory_recursive( $path_to_find_down,
			$dir_to_add_down );
		return $dir->add_directory( name => $dir_to_add );

	}
} ## end sub _add_directory_recursive

sub add_directory {
	my $self = shift;

	my $new_dir = Perl::Dist::WiX::Tag::Directory->new(
		parent => $self,
		@_
	);
	$self->add_child_tag($new_dir);

	return $new_dir;
}



sub get_id {
	my $self = shift;
	return $self->get_directory_id();
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Tag::DirectoryRef - <DirectoryRef> tag that knows how to search its children.

=head1 SYNOPSIS

	my $ref_tag = Perl::Dist::WiX::Tag::DirectoryRef->new(
		id => 'Perl'
		# TODO: Document
	);

	# Parameters can be passed as a hash, or a hashref.
	# A hashref is shown.
	my $dir_tag = $ref_tag->add_directory({
		id => 'Vendor',
		name => 'vendor',
		path => 'C:\strawberry\perl\vendor',
	});
	
	my $dir_tag_2 = $ref_tag->get_directory_object('Vendor');

	my $dir_tag = $ref_tag->search_dir({
		path_to_find => 'C:\strawberry\perl\vendor',
		descend => 1,
		exact => 1,
	});
	
=head1 DESCRIPTION

This is an XML tag that refers to a directory that is used in a Perl::Dist::WiX 
based distribution.

=head1 METHODS

This class is a L<WiX3::XML::DirectoryRef> and inherits its API, so only 
additional API is documented here.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Tag::DirectoryRef> object.

If an error occurs, it throws an exception.

It inherits all the parameters described in the 
L<WiX3::XML::DirectoryRef> C<new> method documentation.

=head2 get_directory_object

get_directory_object returns the L<Perl::Dist::WiX::Tag::Directory> object
with the id that was passed in as the only parameter, as long as it is a 
child tag of this reference, or a grandchild/great-grandchild/etc. tag.

If you pass the ID of THIS object in, it gets returned.

An undefined value is returned if no object with that ID could be found. 

=head2 search_dir

Does the same thing as C<Perl::Dist::WiX::Tag::Directory>'s
L<search_dir|Perl::Dist::WiX::Tag::Directory/search_dir> method, so see 
the documentation there.

=head2 add_directory

Returns a L<Perl::Dist::WiX::Tag::Directory|Perl::Dist::WiX::Tag::Directory>
tag with the given parameters and adds it as a child of this tag.

The C<parent> parameter does not need to be given, as it is added as this object.

=head2 get_id

Redirects to C<get_directory_id>.


=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_directoryref.htm>,

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
