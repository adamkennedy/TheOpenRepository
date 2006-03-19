package Perl::PowerToys;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

1;

__END__

=pod

=head1 NAME

Perl::PowerToys - A collection of PPI-based utilities from the author of PPI

=head1 DESCRIPTION

The Perl PowerToys are a neat little collection of utilities for working
with Perl files from Adam Kennedy, the author of L<PPI>.

=head2 ppichangeversion 0.01 0.02

Takes two version numbers.

Scans through all files without the current directory with the statement

  $VERSION = '0.01';

Changes it to the new version.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-PowerToys>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
