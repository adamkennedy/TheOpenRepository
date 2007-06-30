package Identifier::Anon;

=pod

=head1 NAME

Identifier::Anon - An anonymous (type-less) identifier object

=head1 SYNOPSIS

  my $id = Identifier::Anon->new( 12345 );

=head1 METHODS

=cut
use strict;
use base 'Identifier';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Identifier>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<Identifier>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
