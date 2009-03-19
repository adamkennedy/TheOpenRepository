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

use version;
our $VERSION = qv('0.1');

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION->numify);

1;
