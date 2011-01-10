package SDL::Tutorial::3DWorld::3DS;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::3DS - Support for loading 3D models from 3DS files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::3DS->new(
      file => 'mymodel.3ds',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::3DS> provides a basic implementation of a 3DS file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the 3DS object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                      ();
use File::Spec                    ();
use SDL::Tutorial::3DWorld::Mesh  ();
use SDL::Tutorial::3DWorld::Asset ();
use SDL::Tutorial::3DWorld::Model ();

our $VERSION = '0.32';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $handle = shift;
	my $mesh   = SDL::Tutorial::3DWorld::Mesh->new;

	# Fetch a chunk
	my $pos  = 0;
	my $head = '';
	$handle->sysread( $head, 6 );

	# Initialise the mesh elements that need it
	$mesh->init;
	$self->{box} = [ $mesh->box ];

	# Generate the display list
	return $mesh->as_list;
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
