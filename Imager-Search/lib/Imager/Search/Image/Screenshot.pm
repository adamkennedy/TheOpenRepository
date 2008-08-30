package Imager::Search::Image::Screenshot;

=pod

=head1 NAME

Imager::Search::Image::Screenshot - An image captured from the screen

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use strict;
use Carp               ();
use Params::Util       qw{ _ARRAY0 _INSTANCE };
use Imager::Screenshot ();
use base 'Imager::Search::Image::File';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my @params = ();
	@params = @{shift()} if _ARRAY0($_[0]);
	my $image = Imager::Screenshot::screenshot( @params );
	unless ( _INSTANCE($image, 'Imager') ) {
		Carp::croak('Failed to capture screenshot');
	}

	# Hand off to the parent class
	return $class->SUPER::new( image => $image, @_ );
}

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
