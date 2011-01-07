package SDL::Tutorial::3DWorld::Actor::TronBit;


=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::TronBit - An attempt to create "Bit" from Tron

=head1 DESCRIPTION

An attempt to make a complex actor, the "bit" character from tron.

Contains multiple sub-models, continually morphing and moving as a whole.

B<THIS CLASS DOES NOT WORK, AND ACTS ONLY AS A PLACEHOLDER FOR FUTURE WORK>

=cut

use 5.008;
use strict;
use warnings;
use OpenGL::Array                    ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Actor    ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.32';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create the "Yes" tetrahedron
	$self->{yes_material} = SDL::Tutorial::3DWorld::Material->new(
		ambient   => [ 0.2, 0.2, 0.0, 1.0 ],
		diffuse   => [ 0.8, 0.8, 0.0, 1.0 ],
		specular  => [ 1.0, 1.0, 0.0, 1.0 ],
		shininess => 100,
	);

	return $self;
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
