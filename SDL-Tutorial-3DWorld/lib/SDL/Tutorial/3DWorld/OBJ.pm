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
use IO::File                   1.14 ();
use File::Spec                 3.31 ();
use OpenGL                     0.64 ':all';
use OpenGL::List               0.01 ();
use SDL::Tutorial::3DWorld::Texture ();

our $VERSION = '0.20';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "OBJ model file '$file' does not exists";
	}

	# Texture cache
	$self->{textures} = { };

	return $self;
}

sub file {
	$_[0]->{file}
}

sub list {
	$_[0]->{list};
}





######################################################################
# Main Methods

sub display {
	glCallList( $_[0]->{list} );
}

sub init {
	my $self   = shift;
	my $handle = IO::File->new( $self->file, 'r' );
	$self->parse( $handle );
	$handle->close;
	return 1;
}





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
					my $sn = surface( @v0, @v1, @v2 );
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
					my $sn = surface( @v0, @v1, @v2 );
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

# Calculate a surface normal
sub surface {
	my ($x0, $y0, $z0, $x1, $y1, $z1, $x2, $y2, $z2) = @_;

	# Calculate vectors A and B
	my $xa = $x0 - $x1;
	my $ya = $y0 - $y1;
	my $za = $z0 - $z1;
	my $xb = $x1 - $x2;
	my $yb = $y1 - $y2;
	my $zb = $z1 - $z2;

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Normalise the vector
	my $l = sqrt( ($xn * $xn) + ($yn * $yn) + ($zn * $zn) ) || 1;
	return [ $xn / $l, $yn / $l, $zn / $l ];
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
