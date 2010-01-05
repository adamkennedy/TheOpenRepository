#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Aspect;

my $aspect = aspect Wormhole => "ClassA::a", "ClassC::c";
my $object = ClassA->new;
is( $object->a, $object, 'C::c returns instance of calling A' );

package ClassA;

sub new { bless {}, shift }

sub a { ClassB->b }

package ClassB;

sub b { ClassC->c }

package ClassC;

sub c { pop }
