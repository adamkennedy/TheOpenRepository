package PPI::PowerToys;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.07';
}

1;

__END__

=pod

=head1 NAME

PPI::PowerToys - A handy collection of small PPI-based utilities

=head1 DESCRIPTION

The PPI PowerToys are a small collection of utilities for working
with Perl files compiled by Adam Kennedy, the author of L<PPI>.

To kick off the collection, he's added a very simple and raw version of
one of his own little tools.

=head2 ppi_version

  > ppi_version change 0.01 0.02

ppi_version is a small utility for working with version numbers in groups
of modules.

At the present time it only offers the "change" command, which takes a
version number to change from and to.

It scans through all files inside the current directory with one-only
instance of the line.

  $VERSION = '0.01';

If the version matches the from version, it (safely) changes it to the
new replacement version.

=head1 TO DO

- Add extra commands to ppi_version

- Do you have a handy PPI-based utility you'd like to contribute?

- Any improvements to the current PPI toys are also very welcome.

=head1 SUPPORT

Bugs and patches should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI-PowerToys>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
