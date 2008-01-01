#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use Perl::Exe;

is( $Perl::Exe::EXE, undef, '$EXE is initially undef' );
my $discover = Perl::Exe::discover;
is( $Perl::Exe::EXE, undef, '->discover does not set $EXE' );
my $exe = Perl::Exe::find;
ok( -f $discover, 'Found perl executable via ->discover' );
ok( -f $exe, 'Found perl executable via ->exe' );
is( $discover, $exe, '->discover and ->exe return the same' );
is( $exe, $Perl::Exe::EXE, 'The $EXE cache is set as expecte' );
$Perl::Exe::EXE = 'foo';
is( Perl::Exe::find, 'foo', '->find uses cache as expected' );
$Perl::Exe::EXE = undef;

# Check that run3 works as expected
my $out = '';
my $rv  = Perl::Exe::run3(
	[ '-e', 'print "Hello World!\n"; exit;' ],
	\undef,
	\$out,
	\undef,
);

is( $rv, 1, 'run3 returns true' );
is( $out, "Hello World!\n", 'STDOUT matches expected' );
