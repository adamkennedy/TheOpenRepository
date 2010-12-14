package SDL::Tutorial::3DWorld::Landscape;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Landscape - The static 3D environment of the world

=head1 DESCRIPTION

A landscape is the "world" part of the 3D World. It will generally just sit
in the same place, looking pretty (ideally) and doing nothing (mostly).

While it may sometimes change in shape, it certainly does not move around
as a whole.

The B<SDL::Tutorial::3DWorld::Landscape> module is responsible for creating
the world, and updating it if needed.

In this demonstration code, the landscape consists of a simple 50m x 50m
white square.

=head1 METHODS

=cut

use strict;
use warnings;
use OpenGL ();

=pod

=head2 new

The C<new> constructor for the landscape. It takes no parameters and
returns an object representing the static part of the game world.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

=pod

=head2 sky

  my ($red, $green, $blue, $alpha) = $landscape->sky;

The C<sky> method returns the colour of the sky as a four element RGBA list,
with each colour a value in the range 0 to 1.

The sky value is the colour that is used to wipe the OpenGL colour buffer
(the buffer that ultimately becomes what appears on your monitor) and so will
serve effectively as the "background colour" for your world.

This value is not currently configurable, and will always return a dark navy
blue.

=cut

sub sky {
	return ( 0, 0.1, 0, 0 );
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Configure the colour that each frame will be cleared with before
	# any objects are drawn. This is effectively the "sky" colour.
	# We get the colour from the sky method, so that later on this value
	# can be configurable.
	OpenGL::glClearColor( $self->sky );

	return 1;
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
