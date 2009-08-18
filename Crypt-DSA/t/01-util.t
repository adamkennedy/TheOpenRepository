#!/usr/bin/perl

use strict;
use Test::More tests => 13;
use Math::BigInt;
use Crypt::DSA::Util qw( bin2mp mp2bin bitsize mod_exp mod_inverse );

my($string, $num, $n);

$string = "abcdefghijklmnopqrstuvwxyz-0123456789";
$num = Math::BigInt->new("48431489725691895261376655659836964813311343892465012587212197286379595482592365885470777");
$n = bin2mp($string);
is($n, $num, 'bin2mp is correct for long string');
is(bitsize($num), 295, 'bitsize is correct for large number');
is(bitsize($n), 295, 'bitsize is correct for large mp');
is(mp2bin($n), $string, 'mp2bin is correct for large number');

$string = "abcd";
$num = 1_633_837_924;
$n = bin2mp($string);
is($n, $num, 'bin2mp is correct for short string');
is(bitsize($num), 31, 'bitsize is correct for small number');
is(bitsize($n), 31, 'bitsize is correct for small mp');
is(mp2bin($n), $string, 'mp2bin is correct for small number');

$string = "";
$num = 0;
$n = bin2mp($string);
is($n, $num, 'bin2mp is correct for empty string');
is(mp2bin($n), $string, 'mp2bin is correct for empty string');

my($n1, $n2, $n3, $n4);
($n1, $n2, $n3, $n4) = map Math::BigInt->new($_), ("23098230958", "35", "10980295809854", "5115018827600");
$num = mod_exp($n1, $n2, $n3);
is($num, $n4, 'mod_exp is correct');

($n1, $n2, $n3) = map Math::BigInt->new($_), ("34093840983", "23509283509", "7281956166");
$num = mod_inverse($n1, $n2);
is($num, $n3, 'mod_inverse is correct');
is(1, ($n1*$num)%$n2, 'mod_inverse reverses correctly');
