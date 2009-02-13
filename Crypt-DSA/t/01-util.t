#!/usr/bin/perl

use strict;
use Test::More tests => 13;
use Math::BigInt;
use Crypt::DSA::Util qw( bin2mp mp2bin bitsize mod_exp mod_inverse );

my($string, $num, $n);

$string = "abcdefghijklmnopqrstuvwxyz-0123456789";
$num = Math::BigInt->new("48431489725691895261376655659836964813311343892465012587212197286379595482592365885470777");
$n = bin2mp($string);
is($n, $num);
is(bitsize($num), 295);
is(bitsize($n), 295);
is(mp2bin($n), $string);

$string = "abcd";
$num = 1_633_837_924;
$n = bin2mp($string);
is($n, $num);
is(bitsize($num), 31);
is(bitsize($n), 31);
is(mp2bin($n), $string);

$string = "";
$num = 0;
$n = bin2mp($string);
is($n, $num);
is(mp2bin($n), $string);

my($n1, $n2, $n3, $n4);
($n1, $n2, $n3, $n4) = map Math::BigInt->new($_), ("23098230958", "35", "10980295809854", "5115018827600");
$num = mod_exp($n1, $n2, $n3);
is($num, $n4);

($n1, $n2, $n3) = map Math::BigInt->new($_), ("34093840983", "23509283509", "7281956166");
$num = mod_inverse($n1, $n2);
is($num, $n3);
is(1, ($n1*$num)%$n2);
