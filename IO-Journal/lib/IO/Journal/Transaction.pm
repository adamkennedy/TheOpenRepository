# IO::Journal::Transaction
#  Provides support for atomic transactions
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

package IO::Journal::Transaction;

use strict;
use warnings;
use Carp ();

=head1 NAME

IO::Journal::Transaction - Perl interface to IO::Journal transactions

=head1 VERSION

Version 0.2 ($Id$)

=cut

use version; our $VERSION = qv('0.2');

=head1 DESCRIPTION

This module provides the facilities for handling C<IO::Journal> transactions.
Operations can be added to the transaction object via the exposed interface;
they can then be either saved to file (commit) or simply discarded (rollback).

=head1 SYNOPSIS

  my $trans = $journal->begin_transaction();
  $trans->write("Hello ");
  $trans->write("World\n");
  $trans->commit(); # may die
  # File either contains "Hello World\n" or nothing

  # Transactions can be rolled back even after committing! (But only if we
  # have a current handle to the transaction)
  $trans->rollback();

=cut

# This is the code that actually bootstraps the module and exposes
# the interface for the user. XSLoader is believed to be more
# memory efficient than DynaLoader.
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head1 SEE ALSO

L<IO::Journal>

=head1 SUPPORT

Please file bugs for this module under the C<IO::Journal> distribution. For
more information, see L<IO::Journal>'s perldoc.

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
