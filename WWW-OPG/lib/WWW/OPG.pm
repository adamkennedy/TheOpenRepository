# Math::Random::ISAAC
#  An interface that automagically selects the XS or Pure Perl port of the
#  ISAAC Pseudo-Random Number Generator
#
# $Id$

package Math::Random::ISAAC;

use strict;
use warnings;
use Carp ();

=head1 NAME

WWW::OPG - Perl interface to Ontario Power Generation's site

=head1 VERSION

Version 1.000 ($Id$)

=cut

our $VERSION = '1.000';
$VERSION = eval $VERSION;

=head1 DESCRIPTION

This module provides a Perl interface to information published on Ontario
Power Generation's web site at L<http://opg.com>.

=head1 SYNOPSIS

  use WWW::OPG;

  my $opg = WWW::OPG->new();
  eval {
    $opg->poll();
  };
  print "Currently generating ", $opg->power, "MW of electricity\n";

=head1 COMPATIBILITY

This module was tested under Perl 5.10.1, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 new

  WWW::OPG->new()

Initialize a C<WWW::OPG> object, setting up the user agent.

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

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::OPG

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-OPG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-OPG>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-OPG>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-OPG>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/WWW-OPG>

=item * CPAN Testers Platform Compatibility Matrix

L<http://www.cpantesters.org/show/WWW-OPG.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/WWW-OPG>

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

L<http://opg.com>, the Ontario Power Generation web site.

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

The only data currently easily available from the Ontario Power Generation
web site is the data for power currently being generated for the province
of Ontario, in MegaWatts (MW). This data seems to be updated every five
minutes.

=back

=head1 QUALITY ASSURANCE METRICS

=head2 TEST COVERAGE


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
