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
use OpenGL::List                       ();
use SDL::Tutorial::3DWorld             ();
use SDL::Tutorial::3DWorld::Actor      ();
use SDL::Tutorial::3DWorld::Asset::OBJ ();
use SDL::Tutorial::3DWorld::Asset::RWX ();
use SDL::Tutorial::3DWorld::Bound;

our $VERSION = '0.32';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Map to the absolute disk file
	$self->{file} = SDL::Tutorial::3DWorld->sharefile( $self->{file} );
	unless ( -f $self->{file} ) {
		die "Model file '$self->{file}' does not exist";
	}

	# Create the type-specific object
	if ( $self->{file} =~ /\.rwx$/ ) {
		$self->{model} = SDL::Tutorial::3DWorld::Asset::RWX->new(
			file  => $self->{file},
		);

	} elsif ( $self->{file} =~ /\.obj$/ ) {
		$self->{model} = SDL::Tutorial::3DWorld::Asset::OBJ->new(
			file  => $self->{file},
			plain => $self->{plain},
		);

	} else {
		die "Unkown or unsupported file '$self->{file}'";
	}

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self  = shift;
	my $model = $self->{model};
	$self->SUPER::init(@_);

	# Load the model display list
	$model->init;

	# Do we need blending support?
	if ( $model->{blending} ) {
		$self->{blending} = 1;
	}

	# Get the bounding box from the model
	my $scale = $self->{scale};
	if ( $scale ) {
		$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
			$model->{box}->[0] * $scale->[0],
			$model->{box}->[1] * $scale->[1],
			$model->{box}->[2] * $scale->[2],
			$model->{box}->[3] * $scale->[0],
			$model->{box}->[4] * $scale->[1],
			$model->{box}->[5] * $scale->[2],
		);
	} else {
		$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
			@{ $model->{box} },
		);
	}

	# Static model optimisations
	unless ( $self->{velocity} ) {
		# Compile the entire display routine
		$self->{display} = OpenGL::List::glpList {
			OpenGL::glPushMatrix();
			OpenGL::glTranslatef( @{$self->{position}} );
			if ( $self->{scale} ) {
				OpenGL::glScalef( @{$self->{scale}} );
			}
			OpenGL::glCallList( $model->{list} );
			OpenGL::glPopMatrix();
		};
	}

	return 1;
}

sub display {
	my $self = shift;

	# Move to the correct location
	$self->SUPER::display(@_);

	# Render the model
	$self->{model}->display;

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
