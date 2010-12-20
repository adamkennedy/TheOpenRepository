package SDL::Tutorial::3DWorld::RWX;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::RWX - Support for loading 3D models from RWX files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::RWX->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::RWX> provides a basic implementation of a RWX file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the RWX object.

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

our $VERSION = '0.18';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "RWX model file '$file' does not exists";
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

	# Set up the (Perl) vertex array.
	# The vertex list starts from position 1, so prepad a null
	my @color     = ( 0, 0, 0 );
	my $ambient   = 0;
	my $diffuse   = 1;
	my $opacity   = 1;
	my @vertex    = ( undef );
	my @normal    = ( undef );
	my @triangles = ( );
	my @quads     = ( );

	# Start the list context
	$self->{list} = OpenGL::List::glpList {
		# Start without texture support and reset specularity
		glEnable( GL_LIGHTING );
		glDisable( GL_TEXTURE_2D );
		OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 20 );
		OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 1, 1, 1, 1 );

		while ( 1 ) {
			my $line = $handle->getline;
			last unless defined $line;

			# Remove blank lines, trailing whitespace and comments
			$line =~ s/\s*(?:#.+)[\012\015]*\z//;
			$line =~ m/\S/ or next;

			# Parse the dispatch the line
			my @words   = split /\s+/, $line;
			my $command = lc shift @words;
			if ( $command eq 'vertex' or $command eq 'vertexext' ) {
				# Only take the first three values, ignore any uv stuff
				push @vertex, [ @words[0..2] ];
				push @normal, [ ];

			} elsif ( $command eq 'color' ) {
				@color = @words;

			} elsif ( $command eq 'ambient' ) {
				$ambient = $words[0];

			} elsif ( $command eq 'diffuse' ) {
				$diffuse = $words[0];

			} elsif ( $command eq 'triangle' ) {
				# Calculate the surface normal
				my $sn = surface(
					@{$vertex[$words[0]]},
					@{$vertex[$words[1]]},
					@{$vertex[$words[2]]},
				);
				push @{ $normal[$words[0]] }, $sn;
				push @{ $normal[$words[1]] }, $sn;
				push @{ $normal[$words[2]] }, $sn;
				push @triangles, [ @words[0..2], $sn ];

			} elsif ( $command eq 'quad' ) {
				# Calculate the surface normal
				my $sn = surface(
					@{$vertex[$words[0]]},
					@{$vertex[$words[1]]},
					@{$vertex[$words[2]]},
				);
				push @{ $normal[$words[0]] }, $sn;
				push @{ $normal[$words[1]] }, $sn;
				push @{ $normal[$words[2]] }, $sn;
				push @{ $normal[$words[3]] }, $sn;
				push @quads, [ @words[0..3], $sn ];

			} elsif ( $command eq 'texture' ) {
				# Load or set the texture
				my $name = shift @words;

			} elsif ( $command eq 'protoend' ) {
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);
				render( \@vertex, \@normal, \@quads, \@triangles );

				# Reset state
				@vertex    = ( undef );
				@normal    = ( undef );
				@quads     = ( );
				@triangles = ( );

				# Reset material
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);

			} else {
				# Unsupported command, silently ignore
			}
		}

		# Shortcut if there is nothing to clean up
		unless ( @triangles or @quads ) {
			return 1;
		}

		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_AMBIENT,
			( map { $_ * $ambient } @color ),
			$opacity,
		);
		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_DIFFUSE,
			( map { $_ * $diffuse } @color ),
			$opacity,
		);
		render( \@vertex, \@normal, \@quads, \@triangles );
	};

	return 1;
}

sub render {
	my $vertex    = shift;
	my $normal    = shift;
	my $quads     = shift;
	my $triangles = shift;

	# Aggregate all of the vector normals
	foreach ( 1 .. $#$normal ) {
		$normal->[$_] = average(@{$normal->[$_]});
	}

	# Generate all of the triangles
	if ( @$triangles ) {
		OpenGL::glBegin( OpenGL::GL_TRIANGLES );
		foreach my $triangle ( @$triangles ) {
			my ($i0, $i1, $i2) = @$triangle;
			OpenGL::glNormal3f( @{$normal->[$i0]} );
			OpenGL::glVertex3f( @{$vertex->[$i0]} );
			OpenGL::glNormal3f( @{$normal->[$i1]} );
			OpenGL::glVertex3f( @{$vertex->[$i1]} );
			OpenGL::glNormal3f( @{$normal->[$i2]} );
			OpenGL::glVertex3f( @{$vertex->[$i2]} );
		}
		OpenGL::glEnd();
	}

	# Generate all of the quads
	if ( @$quads ) {
		OpenGL::glBegin( OpenGL::GL_QUADS );
		foreach my $quad ( @$quads ) {
			my ($i0, $i1, $i2, $i3) = @$quad;
			OpenGL::glNormal3f( @{$normal->[$i0]} );
			OpenGL::glVertex3f( @{$vertex->[$i0]} );
			OpenGL::glNormal3f( @{$normal->[$i1]} );
			OpenGL::glVertex3f( @{$vertex->[$i1]} );
			OpenGL::glNormal3f( @{$normal->[$i2]} );
			OpenGL::glVertex3f( @{$vertex->[$i2]} );
			OpenGL::glNormal3f( @{$normal->[$i3]} );
			OpenGL::glVertex3f( @{$vertex->[$i3]} );
		}
		OpenGL::glEnd();
	}

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

# Calculate a total normal
sub average {
	my $xn = 0;
	my $yn = 0;
	my $zn = 0;

	# Total all of the vectors
	foreach my $v ( @_ ) {
		$xn += $v->[0];
		$yn += $v->[1];
		$zn += $v->[2];
	}

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
