package ADAMK::SDL::Test;

use 5.008;
use strict;
use warnings;
use OpenGL     ':all';
use SDL  2.524 ':all';
use SDL::Event ':all';
use SDLx::App;
# use ADAMK::SDL::Debug;

our $VERSION = '0.01';
our @ISA     = 'SDLx::App';

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(
		gl    => 1,
		title => 'ADAMK - An SDL Experimental',
		@_,
	);

	# Initialise OpenGL
	glEnable( GL_DEPTH_TEST );
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	gluPerspective( 60, $self->width / $self->height, 1, 1000 );
	glTranslatef( 0, 0, -20 );

	my $rotate = [ 0, 0 ];

	# Register event handler
	$self->add_event_handler( sub {
		my $event = shift;
		my $type  = $event->type;

		if ( $type == SDL_MOUSEMOTION ) {
			$rotate = [
				$event->motion_x,
				$event->motion_y,
			];
			return 1;
		}

		if ( $type == SDL_KEYDOWN ) {
			my $key = $event->key_sym;
			print "       Key: $key\n";
			if ( $key == SDLK_LEFT ) {
				print "SDLK_LEFT!\n";
				$self->stop;
			}
			return 1;
		}

		if ( $type == SDL_QUIT ) {
			return 0;
		}

		return 1;
	} );

	# Register the render handler
	$self->add_show_handler( sub {
		my $dt = shift;

		# Clear the screen
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		glColor3d( 0, 1, 1 );

		# Rotate the teapot
		glPushMatrix();
		glRotatef( $rotate->[0], 0, 1, 0 );
		glRotatef( $rotate->[1], 1, 0, 0 );
		glutSolidTeapot(2);
		$self->sync;
		glPopMatrix();
	} );

	return $self;
}

sub key_q {

}

1;

__END__

=pod

=head1 NAME

ADAMK::SDL::Test - Adam's SDL Experiments

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.org<gt>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
