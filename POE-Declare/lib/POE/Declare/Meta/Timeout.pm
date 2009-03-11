package POE::Declare::Meta::Timeout;

=pod

=head1 NAME

POE::Declare::Meta::Event - A named POE event with access to extra methods

=head1 DESCRIPTION

B<POE::Declare::Meta::Timeout> is a sub-class of C<Event> with access to
a number of additional methods relating to timers and alarms.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Event ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.13';
	@ISA     = 'POE::Declare::Meta::Event';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
