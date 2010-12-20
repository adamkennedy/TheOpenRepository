package SDL::Tutorial::3DWorld::OBJ;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::OBJ - Support for loading 3D models from OBJ files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::OBJ->new(
      file => 'mymodel.obj',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::OBJ> provides a basic implementation of a OBJ file
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
use IO::File                      1.14 ();
use File::Spec                    3.31 ();
use OpenGL                        0.64 ':all';
use OpenGL::List                  0.01 ();
use SDL::Tutorial::3DWorld::Model      ();
use SDL::Tutorial::3DWorld::Texture    ();
use SDL::Tutorial::3DWorld::Collection ();

our $VERSION = '0.21';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $handle = shift;

	# Initialise
	my @v = ( undef );
	my @f = ( );
	my $b = 0;

	# Start the list context
	$self->{list} = OpenGL::List::glpList {
		# Start without texture support and reset specularity
		glDisable( GL_TEXTURE_2D );

		# Material settings
		OpenGL::glMaterialfv_p( GL_FRONT, GL_AMBIENT,  0.3, 0.3, 0.3, 1.0 );
		OpenGL::glMaterialfv_p( GL_FRONT, GL_DIFFUSE,  0.7, 0.7, 0.7, 1.0 );
		OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 1.0, 1.0, 1.0, 1.0 );
		OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 90 );

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
				# Only take the first three values, ignore any uv stuff
				push @v, \@words;

			} elsif ( $command eq 'f' ) {
				my @vi = map { /^(\d+)/ ? $1 : () } @words;
				if ( @vi == 3 ) {
					glEnd()                 if $b == 4;
					glBegin( GL_TRIANGLES ) if $b != 3;
					$b = 3;

					# Draw the triangle
					my @v0 = @{$v[$vi[0]]};
					my @v1 = @{$v[$vi[1]]};
					my @v2 = @{$v[$vi[2]]};
					my $sn = $self->surface( @v0, @v1, @v2 );
					glNormal3f( @$sn );
					glVertex3f( @v0 );
					glVertex3f( @v1 );
					glVertex3f( @v2 );

				} elsif ( @vi == 4 ) {
					glEnd()             if $b == 3;
					glBegin( GL_QUADS ) if $b != 4;
					$b = 4;

					# Draw the quad
					my @v0 = @{$v[$vi[0]]};
					my @v1 = @{$v[$vi[1]]};
					my @v2 = @{$v[$vi[2]]};
					my $sn = $self->surface( @v0, @v1, @v2 );
					glNormal3f( @$sn );
					glVertex3f( @v0 );
					glVertex3f( @v1 );
					glVertex3f( @v2 );
					glVertex3f( @{$v[$vi[3]]} );

				}

			} elsif ( $command eq 'g' ) {
				glEnd() if $b;
				$b = 0;

			}

		}

		glEnd() if $b;
		glEnable( GL_TEXTURE_2D );
	};

	return 1;
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
