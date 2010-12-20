package SDL::Tutorial::3DWorld::Actor::Model;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::Model - An actor loaded from a RWX file

=head1 SYNOPSIS

  # Define the model location
  my $model = SDL::Tutorial::3DWorld::Actor::Model->new(
      file => 'torus.rwx',
  );
  
  # Load and compile the model into memory
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

This is an experimental module for loading large or complex shapes from
RWX model files on disk.

=cut

use 5.008;
use strict;
use warnings;
use OpenGL::RWX                   ();
use SDL::Tutorial::3DWorld        ();
use SDL::Tutorial::3DWorld::Actor ();

our $VERSION = '0.19';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Map to the absolute disk file
	$self->{file} = SDL::Tutorial::3DWorld->sharefile( $self->{file} );
	unless ( -f $self->{file} ) {
		die "Model file '$self->{file}' does not exist";
	}

	# Create the RWX object
	$self->{rwx} = OpenGL::RWX->new(
		file => $self->{file},
	);

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Load the model as a display list
	$self->{rwx}->init;
}

sub display {
	my $self = shift;

	# Move to the correct location
	$self->SUPER::display(@_);

	# RWX files are at a scale 1/10th that of our world.
	OpenGL::glScalef( 10, 10, 10 );

	# The test model is oversized a bit, halve it
	OpenGL::glScalef( 0.5, 0.5, 0.5 );

	# Render the model
	$self->{rwx}->display;

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
