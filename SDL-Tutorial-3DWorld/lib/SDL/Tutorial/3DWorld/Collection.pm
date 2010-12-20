package SDL::Tutorial::3DWorld::Collection;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Collection - Abstracts a directory of model resources

=head1 DESCRIPTION

A B<Collection> is a direction containing a variety of different modelling
resources, most often shape files and texture files.

=head1 METHODS

=cut

use strict;
use warnings;
use File::Spec                      ();
use SDL::Tutorial::3DWorld::Texture ();
use SDL::Tutorial::3DWorld::Tile    ();
use SDL::Tutorial::3DWorld::RWX     ();
use SDL::Tutorial::3DWorld::OBJ     ();

our $VERSION = '0.21';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the directory
	$self->{directory} = File::Spec->rel2abs(
		$self->{directory}
	) if defined $self->{directory};
	unless ( $self->directory and -d $self->directory ) {
		die "Missing or invalid directory";
	}

	return $self;
}

sub directory {
	$_[0]->{directory};
}





######################################################################
# Main Methods

sub model {
	my $self = shift;
	my $name = shift;

	# Check for an obj file
	my $obj = File::Spec->catfile(
		$self->directory,
		"$name.obj",
	);
	return SDL::Tutorial::3DWorld::OBJ->new(
		file       => $obj,
		collection => $self,
	) if -f $obj;

	# Check for an obj file
	my $rwx = File::Spec->catfile(
		$self->directory,
		"$name.rwx",
	);
	return SDL::Tutorial::3DWorld::RWX->new(
		file       => $rwx,
		collection => $self,
	) if -f $rwx;

	# No idea what this is
	die "Missing or invalid model name '$name'";
}

sub tile {
	my $self = shift;
	my $name = shift;

	# Check for a jpg texture
	my $jpg = File::Spec->catfile(
		$self->directory,
		"$name.jpg",
	);
	return SDL::Tutorial::3DWorld::Tile->new(
		file => $jpg,
	) if -f $jpg;

	# No idea what this is
	die "Missing or invalid texture name '$name'";
}

sub texture {
	my $self = shift;
	my $name = shift;

	# Check for a jpg texture
	my $jpg = File::Spec->catfile(
		$self->directory,
		"$name.jpg",
	);
	return SDL::Tutorial::3DWorld::Texture->new(
		file => $jpg,
	) if -f $jpg;

	# No idea what this is
	die "Missing or invalid texture name '$name'";
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
