package SDL::Tutorial::3DWorld::Actor::Teapot;


=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::Teapot - A moving teapot within the game world

=head1 SYNOPSIS

  # Create a vertical stack of teapots
  my @stack = ();
  foreach my $height ( 1 .. 10 ) {
      push @stack, SDL::Tutorial::3DWorld::Actor::Teapot->new(
          X => 0,
          Y => $height * 0.30, # Each teapot is 30cm high
          Z => 0,
      );
  }

=head1 DESCRIPTION

SDL::Tutorial::3DWorld::Actor::Teapot is a little teapot, short and stout.

It is drawn with the GLUT C<glutCreateTeapot> function.

=head1 METHODS

This class does not contain any additional methods beyond those in the base
class L<SDL::Tutorial::3DWorld::Actor>.

=cut

use strict;
use warnings;
use OpenGL;
use SDL::Tutorial::3DWorld::Actor ();

our $VERSION = '0.12';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub display {
	my $self = shift;
	$self->SUPER::display(@_);

	# Our teapot is a flat greenish colour.
	glDisable( GL_TEXTURE_2D );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_AMBIENT,  @{$self->{ambient}}  );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_DIFFUSE,  @{$self->{diffuse}}  );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, @{$self->{specular}} );
	OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 85 );

	# Draw the teapot
	OpenGL::glutSolidTeapot(0.20);

	return;
}

1;


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
