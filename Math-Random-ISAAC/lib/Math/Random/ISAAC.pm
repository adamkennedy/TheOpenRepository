# Math::Random::ISAAC
#  An interface that automagically selects the XS or Pure Perl port of the
#  ISAAC Pseudo-Random Number Generator
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

package Math::Random::ISAAC;

use strict;
use warnings;
use Carp ();

=head1 NAME

Math::Random::ISAAC - Perl interface to the ISAAC PRNG Algorithm

=head1 VERSION

Version 1.0.5 ($Id$)

=cut

use version; our $VERSION = qv('1.0.5');

our $DRIVER = 'PP';

# Try to load the XS version first
eval {
  require Math::Random::ISAAC::XS;
};

# Fall back on the Perl version
if ($@) {
  require Math::Random::ISAAC::PP;
}
else {
  $DRIVER = 'XS';
}

=head1 DESCRIPTION

As with other Pseudo-Random Number Generator (PRNG) algorithms like the
Mersenne Twister (see L<Math::Random::MT>), this algorithm is designed to
take some seed information and produce seemingly random results as output.

However, ISAAC (Indirection, Shift, Accumulate, Add, and Count) has different
goals than these commonly used algorithms. In particular, it's really fast -
on average, it requires only 18.75 machine cycles to generate a 32-bit value.
This makes it suitable for applications where a significant amount of random
data needs to be produced quickly, such solving using the Monte Carlo method
or for games.

The results are uniformly distributed, unbiased, and unpredictable unless
you know the seed. The algorithm was published by Bob Jenkins in the late
90s and despite the best efforts of many security researchers, no feasible
attacks have been found to date.

=head2 USAGE WARNING

There was no method supplied to provide the initial seed data by the author.
On his web site, Bob Jenkins writes:

  Seeding a random number generator is essentially the same problem as
  encrypting the seed with a block cipher.

In the same spirit, by default, this module does not seed the algorithm at
all -- it simply fills the state with zeroes -- if no seed is provided.
The idea is to remind users that selecting good seed data for their purpose
is important, and for the module to conveniently set it to something like
C<localtime> behind-the-scenes hurts users in the long run, since they don't
understand the limitations of doing so.

The type of seed you might want to use depends entirely on the purpose of
using this algorithm in your program in the first place. Here are some
possible seeding methods:

=over

=item 1 Math::TrulyRandom

The L<Math::TrulyRandom> module provides a way of obtaining truly random
data by using timing interrupts. This is probably one of the better ways
to seed the algorithm.

=item 2 /dev/random

Using the system random device is, in principle, the best idea, since it
gathers entropy from various sources including interrupt timing, other
device interrupts, etc. However, it's not portable to anything other than
Unix-like platforms, and might not produce good data on some systems.

=item 3 localtime()

This works for basic things like simulations, but results in not-so-random
output, especially if you create new instances quickly (as the seeds would
be the same within per-second resolution).

=item 4 Time::HiRes

In theory, using L<Time::HiRes> is the same as option (2), but you get a
higher resolution time so you're less likely to have the same seed twice.
Note that you need to transform the output into an integer somehow, perhaps
by taking the least significant bits or using a hash function. This would
be less prone to duplicate instances, but it's still not ideal.

=back

=head1 SYNOPSIS

  use Math::Random::ISAAC;

  my $rng = Math::Random::ISAAC->new(@seeds);

  for (0..30) {
    print 'Result: ' . $rng->irand() . "\n";
  }

=head1 PURPOSE

The intent of this module is to provide single simple interface to the two
compatible implementations of this module, namely, L<Math::Random::ISAAC::XS>
and L<Math::Random::ISAAC::PP>.

If, for some reason, you need to determine what version of the module is
actually being included by C<Math::Random::ISAAC>, then:

  print 'Backend type: ', $Math::Random::ISAAC::DRIVER, "\n";

In order to force use of one or the other, simply load the appropriate module:

  use Math::Random::ISAAC::XS;
  my $rng = Math::Random::ISAAC::XS->new();
  # or
  use Math::Random::ISAAC::PP;
  my $rng = Math::Random::ISAAC::PP->new();

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 Math::Random::ISAAC->new( @seeds )

Creates a C<Math::Random::ISAAC> object, based upon either the optimized
C/XS version of the algorithm, L<Math::Random::ISAAC::XS>, or falls back
to the included Pure Perl module, L<Math::Random::ISAAC::PP>.

Example code:

  my $rng = Math::Random::ISAAC->new(time);

This method will return an appropriate B<Math::Random::ISAAC> object or
throw an exception on error.

=cut

# Wrappers around the actual methods
sub new {
  my ($class, @seed) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
  };

  if ($DRIVER eq 'XS') {
    $self->{backend} = Math::Random::ISAAC::XS->new(@seed);
  }
  else {
    $self->{backend} = Math::Random::ISAAC::PP->new(@seed);
  }

  bless($self, $class);
  return $self;
}

=head2 $rng->rand()

Returns a random double-precision floating point number which is normalized
between 0 and 1 (inclusive; it's a closed interval).

Internally, this simply takes the uniformly distributed unsigned integer from
C<$rng-E<gt>irand()> and divides it by C<2**32-1> (maximum unsigned integer
size)

Example code:

  my $next = $rng->rand();

This method will return a double-precision floating point number or throw an
exception on error.

=cut

# This package should have an interface similar to the builtin Perl
# random number routines; these are methods, not functions, so they
# are not problematic
## no critic (ProhibitBuiltinHomonyms)

sub rand {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{backend}->rand();
}

=head2 $rng->irand()

Returns the next unsigned 32-bit random integer. It will return a value with
a value such that: B<0 E<lt>= x E<lt>= 2**32-1>.

Example code:

  my $next = $rng->irand();

This method will return a 32-bit unsigned integer or throw an exception on
error.

=cut

sub irand {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{backend}->irand();
}

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Special thanks to Bob Jenkins E<lt>bob_jenkins@burtleburtle.netE<gt> for
devising this very clever algorithm and releasing it into the public domain.

=item *

Thanks to John L. Allen (contact unknown) for providing a Perl port of the
original ISAAC code, upon which C<Math::Random::ISAAC::PP> is heavily based.
His version is available on Bob's web site, in the SEE ALSO section.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Random::ISAAC

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Random-ISAAC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Random-ISAAC>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Random-ISAAC>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Random-ISAAC>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/Math-Random-ISAAC>

=item * CPAN Testers Platform Compatibility Matrix

L<http://www.cpantesters.org/show/Math-Random-ISAAC.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/Math-Random-ISAAC>

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
so.

=head1 SEE ALSO

L<Math::Random::ISAAC::XS>, the C/XS optimized version of this module, which
will be used automatically if available.

L<http://burtleburtle.net/bob/rand/isaacafa.html>, Bob Jenkins' page about
ISAAC, which explains the algorithm as well as potential attacks.

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

There is no method that allows re-seeding of algorithms. This is not really
necessary because one can simply call C<new> again with the new seed data
periodically.

But he also provides a simple workaround:

  As ISAAC is intended to be a secure cipher, if you want to reseed it,
  one way is to use some other cipher to seed some initial version of ISAAC,
  then use ISAAC's output as a seed for other instances of ISAAC whenever
  they need to be reseeded.

=item *

There is no way to clone a PRNG instance. I'm not sure why this is might
even be necessary or useful. File a bug report with an explanation why and
I'll consider adding it to the next release.

=back

=head1 QUALITY ASSURANCE METRICS

=head2 TEST COVERAGE

  ----------------------- ------ ------ ------ ------ ------ ------
  File                    stmt   bran   cond    sub    pod   total
  ----------------------- ------ ------ ------ ------ ------ ------
  Math/Random/ISAAC.pm    100.0  100.0    n/a  100.0  100.0  100.0
  Math/Random/ISAAC/PP.pm 100.0  100.0    n/a  100.0  100.0  100.0
  Total                   100.0  100.0    n/a  100.0  100.0  100.0

=head1 LICENSE

In a perfect world, I could just say that this package and all of the code
it contains is Public Domain. It's a bit more complicated than that; you'll
have to read the included F<LICENSE> file to get the full details.

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
