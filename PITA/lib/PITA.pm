package PITA;

=pod

=head1 NAME

PITA - The Perl Image Testing System

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

...

=cut

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use PITA::Report;
use PITA::Guest::Driver;
use PITA::Host::ResultServer;

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Perl Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA::Report>, L<PITA::Scheme>, L<PITA::Guest::Driver::Qemu>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
