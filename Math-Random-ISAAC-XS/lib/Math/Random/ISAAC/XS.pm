# Math::Random::ISAAC::XS
#  Interface to the ISAAC Pseudo-Random Number Generator
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

package Math::Random::ISAAC::XS;

use strict;
use warnings;

=head1 NAME

Math::Random::ISAAC::XS - C implementation of the ISAAC PRNG Algorithm

=head1 VERSION

Version 1.0.2 ($Id$)

=cut

use version; our $VERSION = qv('1.0.2');

=head1 SYNOPSIS

This module implements the same interface as C<Math::Random::ISAAC> and can be
used as a drop-in replacement. This is the recommended implementation of the
module, based on Bob Jenkins' reference implementation in C.

Selecting the backend to use manually really only has two uses:

=over

=item *

If you are trying to avoid the small overhead incurred with dispatching method
calls to the appropriate backend modules.

=item *

If you are testing the module for performance and wish to explicitly decide
which module you would like to use.

=back

Example code:

  # With Math::Random::ISAAC
  my $rng = Math::Random::ISAAC->new(time);
  my $rand = $rng->rand();

  # With Math::Random::ISAAC::XS
  my $rng = Math::Random::ISAAC::XS->new(time);
  my $rand = $rng->rand();

=head1 DESCRIPTION

See L<Math::Random::ISAAC> for the full description.

=head1 METHODS

=head2 Math::Random::ISAAC::XS->new( @seeds )

Implements the interface as specified in C<Math::Random::ISAAC>

=head2 $rng->rand()

Implements the interface as specified in C<Math::Random::ISAAC>

=head2 $rng->irand()

Implements the interface as specified in C<Math::Random::ISAAC>

=cut

# This is the code that actually bootstraps the module and exposes
# the interface for the user. XSLoader is believed to be more
# memory efficient than DynaLoader.
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head1 SEE ALSO

L<Math::Random::ISAAC>

=head1 SUPPORT

Please file bugs for this module under the C<Math::Random::ISAAC>
distribution. For more information, see L<Math::Random::ISAAC>'s perldoc.

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
