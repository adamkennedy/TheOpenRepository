package CPAN::Data::Loader;

=pod

=head1 NAME

CPAN::Data::Loader - Populates the CPAN index SQLite database

=head1 DESCRIPTION

This package implements all the functionality required to download
the CPAN index data, parse it, and populate the SQLite database
file.

Because it involves loading a number of otherwise unneeded modules,
this package is B<not> loaded by default with the rest of
L<CPAN::Data>, but may be loaded on-demand if needed.

=head1 METHODS

=cut

use strict;
use Carp           ();
use LWP            ();
use Params::Util   qw{ _INSTANCE };
use Email::Address ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}




#####################################################################
# Transport Methods





#####################################################################
# Parsing Methods

=pod

=head2 load_authors

  CPAN::Data::Loader->load_authors( $schema, $handle );

The C<load_authors> method populates the authors table from the CPAN
F<01mailrc.txt.gz> file.

The C<author> table in the SQLite database should already be empty
B<before> this method is called.

Returns the number of authors added to the database, or throws an
exception on error.

=cut

sub load_authors {
	my $self   = shift;
	my $schema = _INSTANCE(shift, 'DBIx::Class::Schema')
		or Carp::croak("Did not provide a DBIx::Class::Schema param");
	my $handle = _INSTANCE(shift, 'IO::Handle')
		or Carp::croak("Did not provide an IO::Handle param");

	# Process the author records
	my $created = 0;
	while ( my $line = $handle->getline ) {
		unless ( $line =~ /^alias\s+(\w+)\s+\"(.+)\"[\012\015]+$/ ) {
			Carp::croak("Invalid 01mailrc.txt.gz line '$line'");
		}
		my $id    = $1;
		my $email = $2;

		# Parse the full email address to seperate the parts
		my @found = Email::Address->parse($email);
		unless ( @found == 1 ) {
			Carp::croak("Failed to correctly parse email address");
		}

		# Create the record
		$schema->resultset('Author')->create( {
			id    => $id,
			name  => $found[0]->name,
			email => $found[0]->address,
			} );
		$created++;
	}

	$created;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Data>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

C<load_authors> based on L<Parse::CPAN::Authors> by Leon Brocard E<lt>acme@cpan.orgE<gt>

=head1 SEE ALSO

L<CPAN::Data>, L<Parse::CPAN::Authors>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
