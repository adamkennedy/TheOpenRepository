# IO::Journal
#  A file I/O interface with journalling support, based on libjio.
#
# $Id: ISAAC.pm 6045 2009-04-07 02:34:58Z FREQUENCY@cpan.org $
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

package IO::Journal;

use strict;
use warnings;
use Carp ();

=head1 NAME

IO::Journal - Perl interface for journalled file operations

=head1 VERSION

Version 0.1 ($Id: ISAAC.pm 6045 2009-04-07 02:34:58Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('0.1');

=head1 DESCRIPTION

To ensure reliability, some file systems and databases provide support for
something known as journalling. The idea is to ensure data consistency by
creating a log of actions to be taken (called a Write Ahead Log) before
committing them to disk. That way, if a transaction were to fail, the
write ahead log could be used to finish writing the data.

While this functionality is often available with full-fledged databases,
often it is not completely necessary, yet reliability can be desirable.
Other times, the filesystem does not provide support for journalling,
but it can still be desirable. Thankfully, Alberto Bertogli published a
userspace C library called libjio that can provide these features in a
small (less than 1500 lines of code) library with no external dependencies.

This package has been published as a stub for the actual module and as
a bit of a land grab. Expect a working version in a few weeks.

=head1 SYNOPSIS

  use IO::Journal;

  # This is my current idea of what the interface will look like. It
  # may change prior to the actual release.
  my $file = IO::Journal->new('filename.txt');
  $file->print('...');
  # or
  print $file ('...');
  $file->commit;

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Special thanks to Alberto Bertogli E<lt>albertito@blitiri.com.arE<gt> for
developing this useful library and for releasing it into the public domain.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Journal

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Journal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Journal>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Journal>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Journal>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/IO-Journal>

=item * CPAN Testers Platform Compatibility Matrix

L<http://www.cpantesters.org/show/IO-Journal.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/IO-Journal>

If you are a CPAN developer and would like to make modifications to the code
base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the repository
administrator. I only ask that you contact me first to discuss the changes you
wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your bug
report in the form of failing unit tests, you are B<strongly> encouraged to do
so. Regular bug reports are always accepted and appreciated via the CPAN bug
tracker.

=head1 SEE ALSO

L<http://blitiri.com.ar/p/libjio/>, libjio's C project page, which has the
full source code and accompanying Python bindings.

=head1 CAVEATS

I have never developed an IO:: type module before this one, so I'm not
completely aware of the interfaces yet. I hope to make it compatible with
conventional interfaces like IO::Handle, but I might make a mistake.

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head1 LICENSE

Copyleft 2009 by Jonathan Yu <frequency@cpan.org>. All rights reversed.

I, the copyright holder of this package, hereby release the entire contents
therein into the public domain. This applies worldwide, to the extent that
it is permissible by law.

In case this is not legally possible, I grant any entity the right to use
this work for any purpose, without any conditions, unless such conditions
are required by law.

The full details of this can be found in the B<LICENSE> file included in
this package.

=head1 DISCLAIMER OF WARRANTY

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

1;
