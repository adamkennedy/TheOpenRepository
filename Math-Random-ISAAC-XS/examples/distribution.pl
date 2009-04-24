#!/usr/bin/perl -T

# examples/distribution.pl
#  Check the uniformity of the distribution generated by ISAAC by
#  charting it.
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Math::Random::ISAAC::XS;
use Chart::Bars;

=head1 NAME

distribution.pl - Show the distribution of numbers generated

=head1 VERSION

Version 1.0 ($Id$)

=cut

use version; our $VERSION = qv('1.0');

=head1 SYNOPSIS

Usage: distribution.pl

This script plots the distribution of data generated by ISAAC. It's a pretty
simple module but might eventually make something neat, as the data is being
plotted randomly. However it's unlikely to do so, since ISAAC is uniformly
distributed.

It outputs a file named C<chart.png> in the current working directory.
Currently this is hardcoded, but this should probably change in the future.

=head1 DESCRIPTION

This module uses 10 million numbers for graphing, so hopefully it removes
any potential slight nonuniformities caused by the seed.

Currently it just uses an instance seeded once with the time. This isn't
quite as good as using an ISAAC instance to initialize another one, since
it only begins with one seed value and must do enough mixing to start
getting some random-looking data.

Most likely though, the data will just be a uniform-looking graph. If you
find otherwise then you've found a bias with ISAAC, and that's a potential
security bug. In that case, you should contact Bob Jenkins, author of the
algorithm.

=cut

my $no_bins = 50;
my $size = 1 / $no_bins;
my $count = 10_000_000;
my $rng = Math::Random::ISAAC::XS->new(time);
my @bins;

print "Generating some data (this might take a while)...\n";
for (1..$count) {
  my $rand = $rng->rand();
  $bins[$rand*$no_bins]++;
}

print "Creating a chart...\n";
my $chart = Chart::Bars->new(640, 480);
$chart->set(
  title       => 'ISAAC Data Distribution',
  legend      => 'none',
  x_label     => 'Quantile',
  y_label     => 'Number of Items',
  spaced_bars => 0,
  min_val     => 0,
  max_val     => $count / ($no_bins-1),
  max_y_ticks => 10,
);

$chart->add_dataset (1..$no_bins);
$chart->add_dataset (@bins);

$chart->png('chart.png');

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head1 SUPPORT

For support details, please look at C<perldoc Math::Random::ISAAC> and
use the corresponding support methods.

=head1 LICENSE

Copyleft (C) 2009 by Jonathan Yu <frequency@cpan.org>

This script is distributed with the C<Math::Random::ISAAC> package and
related packages to provide a simple demonstration of functionality. It is
hereby released by its author into the public domain.

=head1 SEE ALSO

L<Math::Random::ISAAC>,
L<Math::Random::ISAAC::PP>,
L<Math::Random::ISAAC::XS>,

=cut
