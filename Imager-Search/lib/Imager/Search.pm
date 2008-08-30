package Imager::Search;

=pod

=head1 NAME

Imager::Search - Locate images inside other images

=head1 SYNOPSIS

  use Imager::Search ();
  
  # Load the pattern to search for
  my $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML8',
      file   => 'pattern.bmp',
  );
  
  # Load the image to search in
  my $image = Imager::Search::Image::File->new(
      driver => 'Imager::Search::Driver::HTML8',
      file   => 'target.bmp',
  );
  
  # Execute the search
  my @matches = $image->find( $pattern );
  print "Found " . scalar(@matches) . " matches\n";

=head1 DESCRIPTION

For tasks involving searching for patterns within a string, the regular
expression engine provided with Perl has demonstrated itself to be both
fully featured and extremely fast.

For tasks involving working with images, the CPAN module L<Imager> has
demonstrated robust functionality across all common operating system
platforms, while also being extremely fast.

B<Imager::Search> takes the best features from L<Imager> and the regular
expression engine and combines them to produce a simple pure perl image
recognition engine for systems in which the images are pixel perfect.

=head2 Use Cases

L<Imager::Search> is intended to be useful for a range of tasks involving
images from computing and the digital world.

L<Imager::Search> is B<not> intended to be useful for functionality such
as doing facial recognition or any other tasks involving real world
images.

The range of potential applications include monitoring screenshots from
unmanned kiosk and advertising-screen computers for evidence of crashes
or embarrasing popup messages, or automating interactions with
graphics-intense desktop or website applications that would be otherwise
intractable to traditional application automation methods.

For example, by storing captured image fragments of a set of cards,
a program might conceptually be able to look at a solitaire-type game
and establish the position and identity of all the cards on the screen,
populating a model of the current game state and then allowing the
automation of the playing of the game.

=head2 Methodology

Regular expressions are domain-specific Non-Finite Automata (NFA)
programs designed to detect patterns within strings.

Given the problem of locating a smaller "search image" one or more
times inside a larger "target image", we compile the target image into
a suitable string and compile the search image into a suitable regular
expression.

By executing the search regular expression on the target string, and
translating the results of the run back into image terms, we can
determine the specific location of all instances of the search image
inside the target image with relative ease.

By decomposing the problem of image recognition to a regular expression,
the problem then become the creation of a series of transforms for
generating a suitable search expression, generating a suitable target
string, and deriving the match locations in image terms while removing
any false positive or false negative results.

=head2 The Driver API

While it is fairly easy to conceive of what a potential solution
might look like (for example, by expressing each pixel as a HTML colour
like #000000) the implementation is complicated by the need for all the
code surrounding the regular expression execution to be fast as well.

For example, a 0.01 second regular expression search time is of no value
if compiling the search and target images takes several seconds.

It may also be viable to achieve a shorter total processing time by
storing the target image in a format which is inherently searchable
(such as Windows BMP) and using slower and more complex search expression.

Different implementations may be superior in cases where compiled search
expressions are cached and applied to many target images, versus cases
where compiled target images are cached and search over by many search
expressions.

In a typically Perl fasion, L<Imager::Search> responds to this situation
by not imposing a single solution, but instead defining a driver API for
the transforms, so that a number of different implementations can be used
with the same API in various situations.

=head2 The HTML8 Driver

A default "HTML8" implementation is provided with the module. This is a
reference driver that encodes each pixel as a HTML "#RRGGBB" colour code.

This driver demonstrates fast search times and a simple results transform,
but has an extremely slow method for generating the target images, as slow
as several seconds for a typical screenshot.

Additional faster drivers are already being considered and will hopefully
become available shortly.

=head1 USAGE

The current incarnation of L<Imager::Search> is still, so while the
API for the individual classes are relatively stable, there is not yet
a top level convenience API in the B<Imager::Search> namespace itself.

The typical usage pattern consists of the following steps...

=head2 1. Load the Search Image

  # An image loaded from a file
  use Imager::Search::Image::File ();
  my $image = Imager::Search::Image::File->new(
      driver => 'Imager::Search::Driver::HTML8',
      file   => 'target.bmp',
  );
  
  # An image captured from a screenshot
  use Imager::Search::Image::Screenshot ();
  my $screen = Imager::Search::Image::Screenshot->new(
      driver => 'Imager::Search::Driver::HTML8',
  );

=head2 2. Load the Search Pattern

  # A pattern loaded from a file
  use Imager::Search::Pattern ();
  my $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML8',
      file   => 'pattern.bmp',
  );

=head2 3. Execute the Search

  # Find the first match
  my $first = $image->find_first( $pattern );
  
  # Find all matches
  my @matches = $image->find( $pattern );

=head1 CLASSES

The following is the complete list of classes provided by the main
B<Imager-Search> distribution.

=head2 Imager::Search::Pattern

L<Imager::Search::Pattern> provides compiled search pattern objects

=head2 Imager::Search::Match

L<Imager::Search::Match> provides objects that represent locations in
images where a pattern was found.

=head2 Imager::Search::Driver

L<Imager::Search::Driver> is the abstract driver interface. It cannot
be instantiated directly, but it describes (in both code and documentation)
what any driver needs to implement.

=head2 Imager::Search::Driver::HTML8

L<Imager::Search::Driver::HTML8> is an 8-bit reference driver that uses
HTML colour codes (#RRGGBB) to represent each pixel.

=head2 Imager::Search::Image

L<Imager::Search::Image> describes the abstract interface for a search
image. This class also provides the main implementations of the core
search methods.

=head2 Imager::Search::Image::File

L<Imager::Search::Image::File> provides an L<Imager::Search::Image>
sub-class that allows the loading of search images from local files
(of any image type supported by your L<Imager> installation).

=head2 Imager::Search::Image::Cached

L<Imager::Search::Image::Cached> is a unsupported and only partially
implemented attempt at a caching mechanism for compiled Image objects.

=head2 Imager::Search::Image::Screenshot

L<Imager::Search::Image::Screenshot> is a L<Imager::Search::Image>
subclass that captures an image from the currently active window.

=cut

use 5.006;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

use Imager::Search::Pattern ();
use Imager::Search::Driver  ();
use Imager::Search::Match   ();

1;

=pod

=head1 SUPPORT

No support is available for this module.

However, bug reports may be filed at the following URI.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Imager-Search>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
