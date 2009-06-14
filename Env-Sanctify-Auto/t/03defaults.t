#!/usr/bin/perl -T

# t/03defaults.t
#  Tests that defaults are set properly per operating system
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# $Id: 02core.t 7496 2009-06-13 04:17:20Z FREQUENCY@cpan.org $
#
# All rights to this test script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Env::Sanctify::Auto;

sub for_os {
  my ($os) = @_;

  $^O = $os;

  my $sanctify = Env::Sanctify::Auto->new;
  return $ENV{PATH};
}

is(for_os('Unix'), '/usr/bin:/usr/bin/local', 'Unix default path set');
is(for_os('MSWin32'), '%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem',
  'Win32 default path set');
