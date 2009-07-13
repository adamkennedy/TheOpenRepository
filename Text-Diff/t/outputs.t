#!/usr/local/bin/perl -w

use strict ;
use Test ;
use Text::Diff ;

my @A = map "$_\n", qw( 1 2 3 4 ) ;
my @B = map "$_\n", qw( 1 2 3 5 ) ;

sub _d($) { diff \@A, \@B, { OUTPUT => shift } }

sub slurp { open SLURP, "<" . shift or die $! ; return join "", <SLURP> }

my $expected  = _d undef ;

my @tests = (
sub { ok $expected =~ tr/\n// },

sub { my $o ; _d sub { $o .= shift } ;  ok $o,             $expected },

sub { my @o ; _d \@o ;                  ok join( "", @o ), $expected },

sub {
    open F, ">output.t.foo" or die $! ;
    _d \*F ;
    close F or die $! ;
    ok slurp "output.t.foo", $expected ;
    unlink "output.t.foo" or warn $! ;
},

sub {
    require IO::File ;
    my $fh = IO::File->new( ">output.t.foo" ) ;
    _d $fh ;
    $fh = undef ;
    ok slurp "output.t.foo", $expected ;
    unlink "output.t.foo" or warn $! ;
},

sub { ok 0 < index( diff( \"\n", \"", { STYLE => "Table" } ), "\\n" ) },

# test for bug reported by Ilya Martynov <ilya@martynov.org> 
sub { ok diff( \"", \"" ), "" },
sub { ok diff( \"A", \"A" ), "" },
) ;

plan tests => scalar @tests ;

$_->() for @tests ;
