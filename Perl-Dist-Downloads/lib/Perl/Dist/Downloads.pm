package Perl::Dist::Downloads;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

1;

__END__

=pod

=head1 NAME

Perl::Dist::Downloads - The downloads required to build Vanilla Perl distros

=head1 DESCRIPTION

This distribution has no servicable parts.

It provides various zips and tarballs needed to build a Win32 Perl
distribution.

It is distributed separately so that the main Perl-Dist distribution
(which will change far more often than the downloads) won't be bloated
out to 25 meg.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Cyopright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
