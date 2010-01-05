#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use Aspect;

my $good = 'SomePackage::some_method';
my $bad  = 'SomePackage::no_method';

pointcut_ok( string => 'SomePackage::some_method' );
pointcut_ok( re     => qr/some_method/            );
pointcut_ok( code   => sub { shift eq $good }     );

sub pointcut_ok {
	my $type  = shift;
	my $subject = Aspect::Pointcut::Call->new(shift);
	ok(   $subject->match_define($good), "$type match"    );
	ok( ! $subject->match_define($bad),  "$type no match" );
}
