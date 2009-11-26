#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More;
use t::lib::Marpa::Test;

BEGIN {
    if ( eval { require HTML::PullParser } ) {
        Test::More::plan tests => 3;
    }
    else {
        Test::More::plan skip_all => 'Scalar::Util::weaken() not implemented';
    }
    Test::More::use_ok('Marpa');
    Test::More::use_ok('Marpa::UrHTML');
} ## end BEGIN

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);

my $document = do { local $RS = undef; <STDIN> };

sub begin_and_end {
    my ($literal) = @_;
    my $sample_size = 300;
    my $sample;
    if (length ${$literal} < $sample_size) {
        return ${$literal};
    }
    my $first = substr(${$literal}, 0, ($sample_size/2));
    chomp $first;
    my $last = substr(${$literal}, -($sample_size/2));
    chomp $last;
    return "$first\n[ ... ] $last";
}

my $p = Marpa::UrHTML->new(
    {   
    # trace_rules => 1,
    # trace_terminals => 1,
    trace_cruft => 1,
    trace_ambiguity => 1,
    # trace_QDFA => 1,
    handlers => [
            [   ':PROLOG' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "PROLOG starting at line $line:\n" . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'html' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "ROOT stating at line $line:\n" . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'head' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "HEAD stating at line $line:\n" . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'body' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "BODY stating at line $line:\n" . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'table' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "TABLE at line $line:\n"
                        . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'p' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "P at line $line:\n"
                        . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   'option' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "OPTION at line $line:\n"
                        . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
            [   ':CRUFT' => sub {
                    my $literal = Marpa::UrHTML::literal() // \q{!?!};
                    my ( $dummy, $line ) = Marpa::UrHTML::offset();
                    say STDERR "CRUFT at line $line:\n" . begin_and_end($literal) . "\n";
                    return;
                    }
            ],
        ],
    }
);
my $value = $p->parse( \$document );

# say ref $value
    # ? ref ${$value}
        # ? ${ ${value} }
            # ? ${ ${ ${value} } }
            # : 'parse was undef'
        # : 'parse returned ref to undef'
    # : 'parse returned undef';

