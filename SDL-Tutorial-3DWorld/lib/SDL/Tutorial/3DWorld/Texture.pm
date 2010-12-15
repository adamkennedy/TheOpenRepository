package SDL::Tutorial::3DWorld::Texture;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Texture - A texture API simple enough for mere mortals

=head1 SYNOPSIS

  # Create the texture object (validating only the file exists)
  my $texture = SDL::Tutorial::3DWorld::Texture->new( file => $file );
  
  # Load the texture into memory, ready for use in your program
  $texture->init;
  
  # Make this texture the active OpenGL texture for drawing
  $texture->display;

=head1 DESCRIPTION

OpenGL textures are a large and complex topic, with a steep learning curve.

Most tutorials on texturing demonstrate a single specific use case, and
often implement their own image loaders in the process. Unlike most other
basic topics in OpenGL, texturing examples are difficult to translate into
working code for your own program (and even then the amount of code can
be rather large and crufty).

This module provides a convenient abstraction that streamlines the most
obvious case of reading an image file from disk, binding it to the OpenGL
environment, and then activating the texture so you can paint it onto
something.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL     ();
use SDL::Image ();
use SDL::Video ();

# Ensure all the OpenGL "constants" are loaded
use SDL::Tutorial::3DWorld ();

our $VERSION = '0.03';

=pod

=head2 new

  # Load a texture from a shared file texture collection
  my $chess = SDL::Tutorial::3DWorld::Texture->new(
      file => File::Spec->catfile(
          File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
          'textures',
          'chessboard.png',
      ),
  );

The C<new> constructor creates a new texture handle which identifies a
texture to be loaded from disk.

It takes a single named C<file> parameter which should be the path to
the texture on disk. While the C<new> constructor will validate that the
file exists, it will not attempt to load the image. Any image files that
are broken, corrupt or unsupported will not be identified until C<init>
is called.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the file
	unless ( -f $self->file ) {
		die "Texture file '" . $self->file . "' does not exist";
	}

	return $self;
}

=pod

=head2 file

The C<file> accessor returns the path to the file the texture was
originally loaded from.

=cut

sub file {
	$_[0]->{file};
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;

	# Use SDL to load the image
	my $image = SDL::Image::load( $self->file );

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
			$mask = OpenGL::GL_RGBA;
		} else {
			$mask = OpenGL::GL_BGRA;
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
		OpenGL::GL_LINEAR, # OpenGL::GL_NEAREST,
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

sub display {
	OpenGL::glBindTexture( OpenGL::GL_TEXTURE_2D, $_[0]->{id} );
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
