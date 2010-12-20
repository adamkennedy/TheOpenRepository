package SDL::Tutorial::3DWorld::Camera::Fly;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Camera::Fly - A "God Mode" flying person camera

=head1 DESCRIPTION

A flying-mode camera is a camera in which the "move" direction occurs in
three dimensions rather than two dimensions.

In addition, a different set of movement modifiers apply to a flying
camera than apply to a plain or walking camera.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL;
use SDL::Mouse;
use SDL::Constants                 ();
use SDL::Tutorial::3DWorld::Camera ();

our $VERSION = '0.20';
our @ISA     = 'SDL::Tutorial::3DWorld::Camera';

use constant D2R => CORE::atan2(1,1) / 45;

sub new {
	my $self = shift->SUPER::new(@_);

	# Store the original speed for later
	$self->{speed_original} = $self->{speed};

	return $self;
}





######################################################################
# Engine Interface

sub move {
	my $self  = shift;
	my $step  = shift;
	my $down  = $self->{down};

	# The shift key will allow continuous exponential
	# acceleration of around 5% per second.
	if ( $down->{SDL::Constants::SDLK_LSHIFT} ) {
		$self->{speed} += $self->{speed} * 0.05 * $step;
	} else {
		$self->{speed} = $self->{speed_original};
	}

	# Find the camera-wards and sideways components of our velocity
	my $speed = $self->{speed} * $step;
	my $move  = $speed * (
		$down->{SDL::Constants::SDLK_s} -
		$down->{SDL::Constants::SDLK_w}
	);
	my $strafe = $speed * (
		$down->{SDL::Constants::SDLK_d} -
		$down->{SDL::Constants::SDLK_a}
	);

	# Apply this movement in the direction of the camera
	my $angle     = $self->{angle}     * D2R;
	my $elevation = $self->{elevation} * D2R;
	$self->{X} += (cos($angle) * $strafe) - (sin($angle) * $move);
	$self->{Y} += (sin($elevation) * $move);
	$self->{Z} += (sin($angle) * $strafe) + (cos($angle) * $move);

	# Clip to the zero plain
	$self->{Y} = 1.5 if $self->{Y} < 1.5;

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
