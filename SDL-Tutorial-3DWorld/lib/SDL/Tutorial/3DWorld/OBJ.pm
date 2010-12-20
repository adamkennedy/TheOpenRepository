package SDL::Tutorial::3DWorld::OBJ;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::OBJ - Support for loading 3D models from OBJ files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::OBJ->new(
      file => 'mymodel.obj',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::OBJ> provides a basic implementation of a OBJ file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the OBJ object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                   1.14 ();
use File::Spec                 3.31 ();
use OpenGL                     0.64 ':all';
use OpenGL::List               0.01 ();
use SDL::Tutorial::3DWorld::Texture ();

our $VERSION = '0.20';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "OBJ model file '$file' does not exists";
	}

	# Texture cache
	$self->{textures} = { };

	return $self;
}

sub file {
	$_[0]->{file}
}

sub list {
	$_[0]->{list};
}





######################################################################
# Main Methods

sub display {
	glCallList( $_[0]->{list} );
}

sub init {
	my $self   = shift;
	my $handle = IO::File->new( $self->file, 'r' );
	$self->parse( $handle );
	$handle->close;
	return 1;
}





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $handle = shift;

	# Initialise
	my @vertex = ( undef );

	# Start the list context
	$self->{list} = OpenGL::List::glpList {
		# Start without texture support and reset specularity
		glEnable( GL_LIGHTING );
		glDisable( GL_TEXTURE_2D );
		OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 20 );
		OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 1, 1, 1, 1 );

		while ( 1 ) {
			my $line = $handle->getline;
			last unless defined $line;

			# Remove blank lines, trailing whitespace and comments
			$line =~ s/\s*(?:#.+)[\012\015]*\z//;
			$line =~ m/\S/ or next;

			# Parse the dispatch the line
			my @words   = split /\s+/, $line;
			my $command = lc shift @words;
			if ( $command eq 'v' ) {
				# Only take the first three values, ignore any uv stuff
				push @vertex, [ @words[0..2] ];

			}


		}
	};

	return ;
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
