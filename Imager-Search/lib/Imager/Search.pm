package Imager::Search;

=pod

=head1 NAME

Imager::Search - Locate images inside other images

=head1 DESCRIPTION

To be completed.

=cut

use 5.005;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Imager::Search::Pattern ();
use Imager::Search::Driver  ();
use Imager::Search::Match   ();





#####################################################################
# Main Methods

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
