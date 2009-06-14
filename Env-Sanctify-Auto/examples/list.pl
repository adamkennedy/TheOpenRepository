#!/usr/bin/perl -T

# examples/list.pl
#  List files in the current directory using `ls'
#
# $Id: checkmanifest.t 5633 2009-03-14 20:00:03Z FREQUENCY@cpan.org $
#
# All rights to this example script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Env::Sanctify::Auto;
my $sanctify = Env::Sanctify::Auto->new;

## Try this script with and without $sanctify
## Uncomment to see taint exception:
# undef($sanctify);

print `ls`;
