# IO::Journal
#  A file I/O interface with journalling support, based on libjio.
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

package IO::Journal;

use strict;
use warnings;
use Carp ();

use Fcntl (
  'O_RDONLY',
  'O_RDWR',
  'O_CREAT',
  'O_TRUNC',
  'O_APPEND',
);

use IO::Journal::Transaction;

=head1 NAME

IO::Journal - Perl interface for journalled file operations

=head1 VERSION

Version 0.101 ($Id$)

=cut

use version; our $VERSION = qv('0.101');

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux i686. It provides
some convenience methods similar to C<IO::Handle>, but most of the work is
based on libjio, which must be installed before this module will compile.

Unfortunately, that may require root access on your system. In the future, an
C<Alien::> (a la SVN) or C<::Amalgamation> (a la DBD::SQLite) package may help
streamline this process.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 DESCRIPTION

To ensure reliability, some file systems and databases provide support for
something known as journalling. The idea is to ensure data consistency by
creating a log of actions to be taken (called a Write Ahead Log) before
committing them to disk. That way, if a transaction were to fail due to a
system crash or other unexpected event, the write ahead log could be used to
finish writing the data.

While this functionality is often available with networked databases, it can
be a rather memory- and processor-intensive solution, even where reliable
writes are important. In other cases, the filesystem does not provide native
journalling support, so other tricks may be used to ensure data integrity,
such as writing to a separate temporary file and then overwriting the file
instead of modifying it in-place. Unfortunately, this method cannot handle
threaded operations appropriately.

Thankfully, Alberto Bertogli published a userspace C library called libjio
that can provide these features in a small (less than 1500 lines of code)
library with no external dependencies.

=head1 NOTICE

This module is currently a B<preview release>. Please, please, PLEASE don't
use it for production use yet, until all the kinks have been found and
sorted out.

=head1 SYNOPSIS

  use IO::Journal;

  my $journal = IO::Journal->open('>', 'filename.txt');

  # Start a new transaction
  my $trans = $journal->begin_transaction();
  $trans->syswrite("Hello");
  $trans->syswrite("World\n");
  $trans->commit;
  # File now contains "Hello World\n"

  $trans->rollback;
  # File is now blank

=cut

# This is the code that actually bootstraps the module and exposes
# the interface for the user. XSLoader is believed to be more
# memory efficient than DynaLoader.
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# In order to mimic the Perl open function, we must map the following Perl
# flags to their fopen counterparts:
#
# Perl   C   Flags
#   <    r   O_RDONLY
#  +<    r+  O_RDWR
#   >    w   O_RDWR | O_CREAT | O_TRUNC
#  +>    w+  O_RDWR | O_CREAT | O_TRUNC
#  >>    a   O_RDWR | O_CREAT | O_APPEND
# +>>    a+  O_RDWR | O_CREAT | O_APPEND
#
# The Fcntl core module provides these constants.
my %FLAGMAP = (
  # Mode   Unix-style flags
  '<'   => O_RDONLY,
  '+<'  => O_RDWR,
  '>'   => O_RDWR | O_CREAT | O_TRUNC,
  '+>'  => O_RDWR | O_CREAT | O_TRUNC,
  '>>'  => O_RDWR | O_CREAT | O_APPEND,
  '+>>' => O_RDWR | O_CREAT | O_APPEND,
);

sub open {
  my ($self, $mode, $filename) = @_;

  Carp::croak('Unrecognized mode: ' . $mode)
    unless exists($FLAGMAP{$mode});

  return $self->sysopen($filename, $FLAGMAP{$mode});
}

sub begin_transaction {
  my ($self) = @_;

  return IO::Journal::Transaction->new($self);
}

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Special thanks to Alberto Bertogli E<lt>albertito@blitiri.com.arE<gt> for
developing this useful library and for releasing it into the public domain.
He was very patient while developing this library, and was always open to
new ideas.

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
