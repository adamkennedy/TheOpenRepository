package SDL::Tutorial::3DWorld::Asset::OBJ;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Asset::OBJ - Support for loading 3D models from OBJ files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::Asset::OBJ->new(
      file => 'mymodel.obj',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::Asset::OBJ> provides a basic implementation of a OBJ file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the OBJ object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                            ();
use File::Spec                          ();
use OpenGL                              ':all';
use OpenGL::List                        ();
use SDL::Tutorial::3DWorld::Model       ();
use SDL::Tutorial::3DWorld::Asset::Mesh ();

our $VERSION = '0.23';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





######################################################################
# Parsing Methods

sub parse {
	my $self     = shift;
	my $handle   = shift;
	my $mesh     = SDL::Tutorial::3DWorld::Asset::Mesh->new;
	my $material = 0;

	# Fill the mesh
	while ( 1 ) {
		my $line = $handle->getline;
		last unless defined $line;

		# Remove blank lines, trailing whitespace and comments
		$line =~ s/\s*(?:#.+)[\012\015]*\z//;
		$line =~ m/\S/ or next;

		# Parse the dispatch the line
		my @words   = split /\s+/, $line;
		my $command = lc shift @words;
		if ( $command eq 'v' ) {
			# Create the vertex
			$mesh->add_vertex( @words );

		} elsif ( $command eq 'vn' ) {
			# Create the normal
			$mesh->add_normal( @words );

		} elsif ( $command eq 'f' ) {
			my @vi = map { /^(\d+)/ ? $1 : () } @words;
			if ( @vi == 3 ) {
				$mesh->add_triangle( @vi, $material );
			} elsif ( @vi == 4 ) {
				$mesh->add_quad( @vi, $material );
			}

		} elsif ( $command eq 'mtllib' and not $self->{plain} ) {
			# Load the mtllib
			my $mtl = $self->asset->mtl( $words[0] );
			$mtl->init;

		} elsif ( $command eq 'usemtl' and not $self->{plain} ) {
			# Load a material from the mtl file
			my $name   = shift @words;
			my $object = $self->asset->material($name);
			$material = $mesh->add_material($object);

		}
	}

	# Initialise the mesh elements that need it
	$mesh->init;
	$self->{box} = [ $mesh->box ];

	# Generate the display list
	return OpenGL::List::glpList {
		$mesh->display;
	};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenGL-RWX>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
