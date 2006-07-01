package JSAN::Index::Distribution;

# See POD at end for docs

use strict;
use JSAN::Index ();
use base 'JSAN::Index::Extractable';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

JSAN::Index::Distribution->table('distribution');
JSAN::Index::Distribution->columns( Essential =>
	'name', # Name in META.yml       - 'Display-Swap'
	'doc',  # openjsan.org doc path  - '/doc/a/ad/adamk/Display/Swap'
	);
JSAN::Index::Distribution->columns(
	Primary  => 'name',
	);
JSAN::Index::Distribution->has_many(
	releases => 'JSAN::Index::Release',
	);

sub latest_release {
	my $self     = shift;
	my @releases = $self->releases
		or Carp::croak("No releases found for distribution "
			. $self->name );
	@releases = sort { $b->version <=> $a->version } @releases;
	$releases[0];
}

sub extract_resource {
	my $self    = shift;
	my $release = $self->latest_release;
	$release->extract_resource(@_);
}

1;

__END__

=pod

=head1 NAME

JSAN::Index::Distribution - A JavaScript Archive Network (JSAN) Distribution

=head1 DESCRIPTION

This class provides objects for named distributions in the JSAN index.

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, it has the
following methods

=head2 name

The C<name> accessor returns the name of the distribution.

=head2 doc

The C<doc> accessor returns the root-relative location of the documentation
for this distribution on the L<http://openjsan.org/> website.

=head2 releases

The C<releases> method finds and retrieves all of the releases of the
distribution.

Returns a list of L<JSAN::Index::Release> objects.

=head2 latest_release

One distribution generally has a number of releases.

The C<latest_release> method returns the L<JSAN::Index::Release> object
that represents the most recent release of the distribution.

=head2 extract_libs to => $path

The C<extract_libs> method will extract the libraries for the most
recent version of the distribution to the local filesystem.

It takes named parameters to control its behaviour.

=over 4

=item to

The C<to> parameter specifies the destination for the files to be
extracted to. When passed as a single string, this is taken to be a
directory on the local host.

No other destination options other than the local filesystem are
available at this time, but more destination options are expected at
a later date.

=back

Returns the number of files extracted, or dies on error.

=head2 extract_tests to => $path

The C<extract_tests> method will extract the test scripts for the most
recent release of the distribution to the local filesystem.

Returns the number of files extracted, or dies on error.

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
