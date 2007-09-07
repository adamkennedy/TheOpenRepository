package Archive::SQLite;

use strict;
use Carp         ();
use IO::Zlib     ();
use Archive::Tar ();
use SQL::Script  ();
use Parse::CSV   ();

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.01';
}





#####################################################################
# One-Shot Methods

sub extract {
	my $class   = shift;
	my $archive = shift;
	my $sqlite  = shift;

	die "CODE INCOMPLETE";
}

1;

__END__

=pod

=head1 NAME

SQLite::Archive - Version-agnostic storage and manipulation of SQLite databases

=head1 DESCRIPTION

B<WARNING - THIS MODULE (AND RELATED MODULES IN THIS DISTRIBUTION) IS EXPERIMENTAL>

B<MODULE API AND IMPLEMENTATION SUBJECT TO CHANGE WITHOUT NOTICE OR EXPLAINATION>

Documentation to follow at a later date. Please don't spank me :)

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<SQLite::Temp>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
