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
use IO::File                      1.14 ();
use File::Spec                    3.31 ();
use OpenGL                        0.64 ':all';
use OpenGL::List                  0.01 ();
use SDL::Tutorial::3DWorld::Model      ();
use SDL::Tutorial::3DWorld::Collection ();

our $VERSION = '0.21';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





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
				my $sn = $self->surface(
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
				my $sn = $self->surface(
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
				$self->render(
					\@vertex,
					\@normal,
					\@quads,
					\@triangles,
				);

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
		$self->render(
			\@vertex,
			\@normal,
			\@quads,
			\@triangles,
		);
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
