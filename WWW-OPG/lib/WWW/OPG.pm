# WWW::OPG
#  Perl interface to Ontario Power Generation's site
#
# $Id$

package WWW::OPG;

use strict;
use warnings;
use Carp ();

use LWP::UserAgent;
use DateTime;

=head1 NAME

WWW::OPG - Perl interface to Ontario Power Generation's site

=head1 VERSION

Version 1.005 ($Id$)

=cut

our $VERSION = '1.005';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use WWW::OPG;

  my $opg = WWW::OPG->new();
  eval {
    $opg->poll();
  };
  print "Currently generating ", $opg->power, "MW of electricity\n";

=head1 DESCRIPTION

This module provides a Perl interface to information published on Ontario
Power Generation's web site at L<http://www.opg.com>. This module provides
very quick and low-bandwidth queries using the special machine-readable file
proffered by OPG; see L<http://www.opg.com/megafile.txt>.

=head1 COMPATIBILITY

This module was tested under Perl 5.10.1, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 new

  WWW::OPG->new( \%params )

Initialize a C<WWW::OPG> object, setting up the user agent and preparing
for a transaction. Note that you can pass a L<LWP::UserAgent> object or a
subclass thereof, which can include your proxy or UserAgent settings.

Example code:

  my $opg = WWW::OPG->new();
  # or, with some parameters:
  my $opg = WWW::OPG->new({
    useragent => LWP::UserAgent->new()
  });

This method will return an appropriate B<WWW::OPG> object or throw an
exception on error.

=cut

sub new {
  my ($class, $params) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
  };

  if (exists $params->{useragent}) {
    $self->{useragent} = $params->{useragent};
  }
  else {
    my $ua = LWP::UserAgent->new;
    $ua->agent(__PACKAGE__ . '/' . $VERSION . ' ' . $ua->_agent);
    $self->{useragent} = $ua;
  }

  bless($self, $class);
  return $self;
}

=head2 poll

  $opg->poll()

Update data in the C<WWW::OPG> object, C<$obj>, by connecting to the OPG
site and scraping data. The data can then be extracted using the other
methods available in this class.

Example code:

  $opg->poll();

This method will return a true value if an update has been performed, a
false value if the data is unchanged since the last update, or throw an
exception on error.

=cut

sub poll {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  my $ua = $self->{useragent};
  my $r = $ua->get('http://www.opg.com/megafile.txt');

  Carp::croak('Error reading response: ' . $r->status_line)
    unless $r->is_success;

  my ($power, $date) = split(chr(13) . chr(10), $r->content);

  if ($power =~ m{^\s*([0-9]+),?([0-9]+)$})
  {
    $self->{power} = $1 . $2;

    if ($date =~ m{^(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+) (AM|PM)})
    {
      my $hour = $4;
      # 12:00 noon and midnight are a special case
      if ($hour == 12) {
        # 12am is midnight
        if ($7 eq 'AM') {
          $hour = 0;
        }
      }
      elsif ($7 eq 'PM') {
        $hour += 12;
      }

      my $dt = DateTime->new(
        month     => $1,
        day       => $2,
        year      => $3,
        hour      => $hour, # derived from $4
        minute    => $5,
        second    => $6,
        time_zone => 'America/Toronto',
      );

      if (!exists $self->{updated} || $self->{updated} != $dt)
      {
        $self->{updated} = $dt;
        return 1;
      }
      return 0;
    }
  }

  die 'Error parsing response, perhaps the format has changed?';
  return;
}

=head2 power

  $opg->power()

Returns the amount of power being generated by Ontario Power Generation
(OPG) plants, in MegaWatts (MW).

Example code:

  $opg->poll();
  print "Currently generating ", $opg->power, " MW for Ontario\n";

Note that this value may be undefined if the server has not yet been polled,
or if there was a failure polling.

=cut

sub power {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return unless exists $self->{power};
  return $self->{power};
}

=head2 last_updated

  $opg->last_updated()

Returns the date and time that the data was last updated (as defined by the
remote OPG web server), given as a L<DateTime> object.

Example code:

  $opg->poll();
  print "Last updated ", $opg->last_updated, "\n";

=cut

sub last_updated {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return unless exists $self->{updated};
  return $self->{updated};
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Thanks to the kind folks at OPG and in particular someone I know only as
"Rose" E<lt>webmaster@opg.comE<gt> for providing me with an API in the form
of a small text file which provides the same data as that scraped from the
web page itself. This cuts down significantly on bandwidth costs and the
time it takes to check the data.

=back

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

L<http://www.opg.com>, the Ontario Power Generation web site.

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

  File                     stmt   bran   cond   sub    pod   total
  ----------------------- ------ ------ ------ ------ ------ ------
  lib/WWW/OPG.pm           92.9   71.4   66.7  100.0  100.0   87.1

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
