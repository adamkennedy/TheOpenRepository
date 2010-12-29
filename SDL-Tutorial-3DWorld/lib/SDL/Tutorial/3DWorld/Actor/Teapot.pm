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

our $VERSION = '0.23';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

=pod

=head2 new

  # I want to be a little teapot, short and stout (and the default colour)
  my $teapot = SDL::Tutorial::3DWorld::Actor::Teapot->new(
      size => 0.15, # 15cm
  );

In additional to the regular material properties provided by the parent
L<SDL::Tutorial::3DWorld::Actor> class teapots take an additional C<size>
parameter to control how big the teapot is.

Teapots are 20cm high by default (because tea is best with friends and so
we'll need to brew several cups).

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(
		@_,
	);

	# By default teapots are about 20cm in size (I'm making this up)
	$self->{size} = 0.20;

	return $self;
}





######################################################################
# Engine Interface Methods

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Generate the bounding box
	$self->{box} = [
		$self->{size} * -1.5,
		$self->{size} * -0.75,
		$self->{size} * -1,
		$self->{size} * 1.75,
		$self->{size} * 0.85,
		$self->{size} * 1,
	];

	return 1;
}

sub display {
	my $self = shift;
	$self->SUPER::display(@_);

	# The teapot does not handle face culling, so disable temporarily.
	# We also want pure coloured teapots, so disable textures.
	glDisable( GL_CULL_FACE  );

	# Draw the teapot.
	$self->{material}->display;
	OpenGL::glutSolidTeapot($self->{size});

	# Reset the temporary disabling
	glEnable( GL_CULL_FACE  );

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
