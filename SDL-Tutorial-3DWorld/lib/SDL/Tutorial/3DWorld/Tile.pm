package SDL::Tutorial::3DWorld::Tile;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Tile - A texture that can repeat without seams

=head1 SYNOPSIS

  # Create the texture object (validating only the file exists)
  my $tile = SDL::Tutorial::3DWorld::Texture->new( file => $file );
  
  # Load the texture into memory, ready for use in your program
  $tile->init;
  
  # Make this texture the active OpenGL texture for drawing
  $tile->display;

=head1 DESCRIPTION

A B<Tile> is a texture which can be repeated endlessly without visible edges
between the repetitions.

=head1 METHODS

=cut

use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL  ();
use SDL::Tutorial::3DWorld::Texture ();

our $VERSION = '0.21';
our @ISA     = 'SDL::Tutorial::3DWorld::Texture';





######################################################################
# Engine Methods

sub init {
	my $self = shift;

	# Enable texture support
	OpenGL::glEnable( OpenGL::GL_TEXTURE_2D );

	# Use SDL to load the image
	my $image = SDL::Image::load( $self->file );

	# Check if the image actually got loaded
	Carp::croak( 'Cannot load image at ' . $self->file ) unless $image;

	# Tell SDL to leave the memory the image is in exactly where
	# it is, so that OpenGL can bind to it directly.
	SDL::Video::lock_surface($image);

	# Does this image have a usable texture format?
	my $bytes = $image->format->BytesPerPixel;
	my $mask  = undef;
	if ( $bytes == 4 ) {
		# Contains an alpha channel
		if ( $image->format->Rmask == 0x000000ff ) {
			$mask = OpenGL::GL_RGBA;
		} else {
			$mask = OpenGL::GL_BGRA;
		}
	} elsif ( $bytes == 3 ) {
		# Does not contain an alpha channel
		if ( $image->format->Rmask == 0x000000ff ) {
			$mask = OpenGL::GL_RGB;
		} else {
			$mask = OpenGL::GL_BGR;
		}
	} else {
		die "Unknown or unsupported image '" . $self->file . "'";
	}

	# Have OpenGL generate one texture object handle.
	# This cannot occur between a glBegin and a glEnd, so all texture
	# objects must be initialised before you start drawing something.
	$self->{id} = OpenGL::glGenTextures_p(1);

	# Bind the texture object for the first time, activating it
	# as the "current" texture and confirming it as 2 dimensional.
	OpenGL::glBindTexture( OpenGL::GL_TEXTURE_2D, $self->{id} );

	# Specify how the texture will display when we are far from the
	# texture and many texture pixels are inside one display pixel.
	# This example uses the fastest and ugliest GL_NEAREST setting.
	# Default is GL_NEAREST_MIPMAP_LINEAR.
	# Prettiest is probably going to be GL_LINEAR_MIPMAP_LINEAR
	OpenGL::glTexParameterf(
		OpenGL::GL_TEXTURE_2D,
		OpenGL::GL_TEXTURE_MIN_FILTER,
		OpenGL::GL_LINEAR_MIPMAP_LINEAR, # OpenGL::GL_NEAREST,
	);

	# Specify the zoom method to use when we are too close to the
	# texture and one texture pixel spreads over many display pixels.
	# This example uses the fastest and ugliest GL_NEAREST setting.
	# The default is GL_LINEAR (those are the only two options).
	OpenGL::glTexParameterf(
		OpenGL::GL_TEXTURE_2D,
		OpenGL::GL_TEXTURE_MAG_FILTER,
		OpenGL::GL_LINEAR, # OpenGL::GL_NEAREST,
	);

	# Wrap the textures
	OpenGL::glTexParameterf(
		OpenGL::GL_TEXTURE_2D,
		OpenGL::GL_TEXTURE_WRAP_S,
		OpenGL::GL_REPEAT,
	);

	# Write the image data into the texture, generating a mipmap for
	# scaling as we do so (so it looks pretty no matter how far away
	# it is).
	OpenGL::gluBuild2DMipmaps_s(
		OpenGL::GL_TEXTURE_2D,
		$bytes,
		$image->w,
		$image->h,
		$mask,
		OpenGL::GL_UNSIGNED_BYTE,
		${ $image->get_pixels_ptr },
	);

	# Save some image properties we might need later
	$self->{width}  = $image->w;
	$self->{height} = $image->h;
	$self->{bytes}  = $bytes;
	$self->{mask}   = $mask;

	return 1;
}

1;

=cut

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDL-Tutorial-3DWorld>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<SDL>, L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
