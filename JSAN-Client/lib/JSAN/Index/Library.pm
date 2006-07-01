package JSAN::Index::Library;

# See POD at end for docs

use strict;
use JSAN::Index ();
use base 'JSAN::Index::Extractable';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.13';
}

JSAN::Index::Library->table('library');
JSAN::Index::Library->columns( Essential =>
	'name',    # Library namespace          - 'Display.Swap'
	'release', # Release containing library - '/dist/ADAMK/Display.Swap-0.01.tar.gz'
	'version', # Library version            - '0.01' or '~'
	'doc',     # Doc path
	);
JSAN::Index::Library->has_a(
	release => 'JSAN::Index::Release',
	);

sub distribution {
	shift()->release->distribution;
}

sub extract_resource {
	shift()->release->extract_resource(@_);
}

1;

__END__

=pod

=head1 NAME

JSAN::Index::Library - A JavaScript Archive Network (JSAN) Software Library

=head1 DESCRIPTION

This class provides objects for the various libraries (software components)
in the JSAN.

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, it has the
following methods

=head2 name

The C<name> accessor returns the name (possibly including the use of
pseudo-namespaces) of the library. e.g. "Test.Simple.Container.Browser"

=head2 release

The C<release> method returns the L<JSAN::Index::Release> object for the
release that the library is defined in.

=head2 version

The C<version> accessor returns the version of the library.

=head2 doc

The C<doc> accessor returns the root-relative location of the documentation
for this library on the L<http://openjsan.org/> website.

=head2 distribution

The C<distribution> method is a shortcut for
C<$library-E<gt>release-E<gt>distribution> and returns the
L<JSAN::Index::Distribution> for the distribution that this library
is of.

=head2 extract_libs to => $path

The C<extract_libs> method will extract the libraries for a release
(i.e. the contents of the C<lib> directory> to the local filesystem.

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

The C<extract_tests> method will extract the test scripts for a release
(i.e. the contents of the C<tests> directory> to the local filesystem.

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
