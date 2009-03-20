# Math::Random::ISAAC::PP
#  A Pure Perl port of the ISAAC Pseudo-Random Number Generator
#
# $Id$
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

package Math::Random::ISAAC::PP;

use strict;
use warnings;

use constant RANDSIZL => 8;
use constant RANDSIZ  => (1 << RANDSIZL);

sub new {
  my ($class, @seed) = @_;

  my $seedsize = scalar(@seed);

  my @mm;
  $#mm = $#seed = RANDSIZ-1; # predeclare the arrays are RANDSIZ large

  # Zero-fill our seed data
  for (my $i = $seedsize; $i < RANDSIZ; $i++) {
    $seed[$i] = 0;
  }

  my $self = {
    randrsl   => \@seed,
    randcnt   => 0,
    randmem   => \@mm,

    randa     => 0,
    randb     => 0,
    randc     => 0,
  };

  # By blessing this class as our parent class, users can 
  bless($self, __PACKAGE__);

  _randinit($self);

  return $self;
}

sub rand {
  my ($self) = @_;

  return ($self->randInt() / (2**32-1))
}

sub randInt {
  my ($self) = @_;

  # Reset the sequence if we run out of random stuff
  if (!$self->{randcnt}--)
  {
    # Call method like this because of our hack above
    _isaac($self);
    $self->{randcnt} = RANDSIZ-1;
  }

  return sprintf('%u', $self->{randrsl}->[$self->{randcnt}]);
}

sub _isaac {
  my ($self) = @_;

  use integer;

  my $mm = $self->{randmem};
  my $r = $self->{randrsl};
  my $a = $self->{randa};
  my $b = $self->{randb} + (++$self->{randc});

  my ($x, $y); # temporary storage

  # The C code deals with two halves of the randmem separately;
  # we deal with it in one loop, by adding the &255 parts
  for (my $i = 0; $i < RANDSIZ; $i++)
  {
    $x = $mm->[$i];
    $a = ($a ^ ($a << 13)) + $mm->[($i + RANDSIZ/2) & 255];
    $mm->[$i] = $y = $mm->[($x >> 2) & 255] + $a + $b;
    $r->[$i] = $b = $mm->[($y >> 10) & 255] + $x;
    $i++;

    $x = $mm->[$i];
    $a = ($a ^ (0x03ffffff & ($a >> 6))) + $mm->[($i + RANDSIZ/2) & 255];
    $mm->[$i] = $y = $mm->[($x >> 2) & 255] + $a + $b;
    $r->[$i] = $b = $mm->[($y >> 10) & 255] + $x;
    $i++;

    $x = $mm->[$i];
    $a = ($a ^ ($a << 2)) + $mm->[($i + RANDSIZ/2) & 255];
    $mm->[$i] = $y = $mm->[($x >> 2) & 255] + $a + $b;
    $r->[$i] = $b = $mm->[($y >> 10) & 255] + $x;
    $i++;

    $x = $mm->[$i];
    $a = ($a ^ (0x0000ffff & ($a >> 16))) + $mm->[($i + RANDSIZ/2) & 255];
    $mm->[$i] = $y = $mm->[($x >> 2) & 255] + $a + $b;
    $r->[$i] = $b = $mm->[($y >> 10) & 255] + $x;

    $self->{randb} = $b;
    $self->{randa} = $a;
  }
}

sub _randinit
{
  my ($self) = @_;

  use integer;

  my ($a, $b, $c, $d, $e, $f, $g, $h);
  $a=$b=$c=$d=$e=$f=$g=$h = 0x9e3779b9;

  my $mm = $self->{randmem};
  my $r = $self->{randrsl};

  for (my $i = 0; $i < 4; $i++)
  {
    $a ^= $b << 11;
    $d +=$a;
    $b +=$c;

    $b ^= 0x3fffffff & ($c >> 2);
    $e += $b;
    $c += $d;

    $c ^= $d << 8;
    $f += $c;
    $d += $e;

    $d ^= 0x0000ffff & ($e >> 16);
    $g += $d;
    $e += $f;

    $e ^= $f << 10;
    $h += $e;
    $f += $g;

    $f ^= 0x0fffffff & ($g >> 4);
    $a += $f;
    $g += $h;

    $g ^= $h << 8;
    $b += $g;
    $h += $a;

    $h ^= 0x007fffff & ($a >> 9);
    $c += $h;
    $a += $b;
  }

  for (my $i = 0; $i < RANDSIZ; $i += 8)
  {
    $a += $r->[$i  ];
    $b += $r->[$i+1];
    $c += $r->[$i+2];
    $d += $r->[$i+3];
    $e += $r->[$i+4];
    $f += $r->[$i+5];
    $g += $r->[$i+6];
    $h += $r->[$i+7];

    $a ^= $b << 11;
    $d += $a;
    $b += $c;

    $b ^= 0x3fffffff & ($c >> 2);
    $e += $b;
    $c += $d;

    $c ^= $d << 8;
    $f += $c;
    $d += $e;

    $d ^= 0x0000ffff & ($e >> 16);
    $g += $d;
    $e += $f;

    $e ^= $f << 10;
    $h += $e;
    $f += $g;

    $f ^= 0x0fffffff & ($g >> 4);
    $a += $f;
    $g += $h;

    $g ^= $h << 8;
    $b += $g;
    $h += $a;

    $h ^= 0x007fffff & ($a >> 9);
    $c += $h;
    $a += $b;

    $mm->[$i  ] = $a;
    $mm->[$i+1] = $b;
    $mm->[$i+2] = $c;
    $mm->[$i+3] = $d;
    $mm->[$i+4] = $e;
    $mm->[$i+5] = $f;
    $mm->[$i+6] = $g;
    $mm->[$i+7] = $h;
  }

  for (my $i = 0; $i < RANDSIZ; $i += 8)
  {
    $a += $mm->[$i  ];
    $b += $mm->[$i+1];
    $c += $mm->[$i+2];
    $d += $mm->[$i+3];
    $e += $mm->[$i+4];
    $f += $mm->[$i+5];
    $g += $mm->[$i+6];
    $h += $mm->[$i+7];

    $a ^= $b << 11;
    $d += $a;
    $b += $c;

    $b ^= 0x3fffffff & ($c >> 2);
    $e += $b;
    $c += $d;

    $c ^= $d << 8;
    $f += $c;
    $d += $e;

    $d ^= 0x0000ffff & ($e >> 16);
    $g += $d;
    $e += $f;

    $e ^= $f << 10;
    $h += $e;
    $f += $g;

    $f ^= 0x0fffffff & ($g >> 4);
    $a += $f;
    $g += $h;

    $g ^= $h << 8;
    $b += $g;
    $h += $a;

    $h ^= 0x007fffff & ($a >> 9);
    $c += $h;
    $a += $b;

    $mm->[$i  ] = $a;
    $mm->[$i+1] = $b;
    $mm->[$i+2] = $c;
    $mm->[$i+3] = $d;
    $mm->[$i+4] = $e;
    $mm->[$i+5] = $f;
    $mm->[$i+6] = $g;
    $mm->[$i+7] = $h;
  }

  _isaac($self);
  $self->{randcnt} = RANDSIZ;
}

1;
