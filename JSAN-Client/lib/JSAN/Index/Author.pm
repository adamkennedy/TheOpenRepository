package JSAN::Index::Author;

# See POD at end for documentation

use strict;
use JSAN::Index ();
use base 'JSAN::Index::CDBI';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

JSAN::Index::Author->table('author');
JSAN::Index::Author->columns( Essential =>
	'login', # AUTHOR login id        - 'adamk'
	'name',  # Full Name              - 'Adam Kennedy'
	         #                          'Han Kwai Teow'
	'doc',   # openjsan.org doc path  - '/doc/a/au/adamk
	'email', # Public email address   - 'jsan@ali.as'
	'url',   # Personal website       - 'http://ali.as/'
	);
JSAN::Index::Author->columns(
	Primary => 'login',
	);
JSAN::Index::Author->has_many(
	releases  => 'JSAN::Index::Release',
	);

1;

__END__

=pod

=head1 NAME

JSAN::Index::Author - A JavaScript Archive Network (JSAN) Author

=head1 DESCRIPTION

This class provides objects that represent authors in the L<JSAN::Index>.

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, this class has
the following additional methods.

=head2 login

The C<login> accessor returns the JSAN author code/login for the author.

=head2 name

The C<name> accessor returns the full name of the author.

=head2 doc

The C<doc> accessor returns the root-relative documentation path for the
author on any L<http://openjsan.org/> mirror.

=head2 email

The C<email> accessor returns the public email address for the author.

=head2 url

The C<url> acessor returns the uri for the authors homepage as a string.

=head2 releases

The C<releases> method finds and retrieves all of the releases for an author.

Returns a list of L<JSAN::Index::Release> objects.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Client>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<JSAN::Index>, L<JSAN::Shell>, L<http://openjsan.org>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
