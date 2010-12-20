package SDL::Tutorial::3DWorld::Model;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Model - Generic support for on disk model files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::Model->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::Model> provides shared functionality across all
of the different model file implementations.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                      1.14 ();
use File::Spec                    3.31 ();
use Params::Util                  1.00 '_INSTANCE';
use OpenGL                        0.64 ':all';
use OpenGL::List                  0.01 ();
use SDL::Tutorial::3DWorld::Texture    ();
use SDL::Tutorial::3DWorld::Collection ();

our $VERSION = '0.21';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "The model file '$file' does not exists";
	}

	# Bootstrap a collection if we were not passed one.
	unless ( $self->{collection} ) {
		my $directory = $self->file;
		$directory =~ s/[\w\._-]+$//;
		$self->{collection} = SDL::Tutorial::3DWorld::Collection->new(
			directory => $directory,
		);
	}
	unless ( _INSTANCE($self->collection, 'SDL::Tutorial::3DWorld::Collection') ) {
		die "Missing or invalid collection";
	}

	return $self;
}

sub file {
	$_[0]->{file}
}

sub collection {
	$_[0]->{collection};
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
	die "Failed to implement parse method";
}

sub render {
	my $self      = shift;
	my $vertex    = shift;
	my $normal    = shift;
	my $quads     = shift;
	my $triangles = shift;

	# Aggregate all of the vector normals
	foreach ( 1 .. $#$normal ) {
		$normal->[$_] = $self->average(@{$normal->[$_]});
	}

	# Generate all of the triangles
	if ( @$triangles ) {
		OpenGL::glBegin( OpenGL::GL_TRIANGLES );
		foreach my $triangle ( @$triangles ) {
			my ($i0, $i1, $i2) = @$triangle;
			OpenGL::glNormal3f( @{$normal->[$i0]} );
			OpenGL::glVertex3f( @{$vertex->[$i0]} );
			OpenGL::glNormal3f( @{$normal->[$i1]} );
			OpenGL::glVertex3f( @{$vertex->[$i1]} );
			OpenGL::glNormal3f( @{$normal->[$i2]} );
			OpenGL::glVertex3f( @{$vertex->[$i2]} );
		}
		OpenGL::glEnd();
	}

	# Generate all of the quads
	if ( @$quads ) {
		OpenGL::glBegin( OpenGL::GL_QUADS );
		foreach my $quad ( @$quads ) {
			my ($i0, $i1, $i2, $i3) = @$quad;
			OpenGL::glNormal3f( @{$normal->[$i0]} );
			OpenGL::glVertex3f( @{$vertex->[$i0]} );
			OpenGL::glNormal3f( @{$normal->[$i1]} );
			OpenGL::glVertex3f( @{$vertex->[$i1]} );
			OpenGL::glNormal3f( @{$normal->[$i2]} );
			OpenGL::glVertex3f( @{$vertex->[$i2]} );
			OpenGL::glNormal3f( @{$normal->[$i3]} );
			OpenGL::glVertex3f( @{$vertex->[$i3]} );
		}
		OpenGL::glEnd();
	}

	return 1;
}

# Calculate a surface normal
sub surface {
	my ($self, $x0, $y0, $z0, $x1, $y1, $z1, $x2, $y2, $z2) = @_;

	# Calculate vectors A and B
	my $xa = $x0 - $x1;
	my $ya = $y0 - $y1;
	my $za = $z0 - $z1;
	my $xb = $x1 - $x2;
	my $yb = $y1 - $y2;
	my $zb = $z1 - $z2;

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Normalise the vector
	my $l = sqrt( ($xn * $xn) + ($yn * $yn) + ($zn * $zn) ) || 1;
	return [ $xn / $l, $yn / $l, $zn / $l ];
}

# Calculate a total normal
sub average {
	my $self = shift;
	my $xn   = 0;
	my $yn   = 0;
	my $zn   = 0;

	# Total all of the vectors
	foreach my $v ( @_ ) {
		$xn += $v->[0];
		$yn += $v->[1];
		$zn += $v->[2];
	}

	# Normalise the vector
	my $l = sqrt( ($xn * $xn) + ($yn * $yn) + ($zn * $zn) ) || 1;
	return [ $xn / $l, $yn / $l, $zn / $l ];
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
