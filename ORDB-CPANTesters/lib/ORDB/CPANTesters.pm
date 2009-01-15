package ORDB::CPANTesters;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.01';

use ORLite::Mirror ();

# Don't pull the database for 'require' (so it needs a full 'use' line)
sub import {
	my $class = shift;

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import('http://testers.cpan.org/testers.db.bz2');

	return 1;
}

1;

__END__

=pod

=head1 NAME

ORDB::CPANTesters - ORM Client for the CPAN Testers database

=head1 DESCRIPTION

TO BE COMPLETED

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORDB-CPANTesters>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
