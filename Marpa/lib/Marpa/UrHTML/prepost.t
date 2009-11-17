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

my $p = Marpa::UrHTML->new(
    {   handlers => [
            [   'PROLOG' => sub {
                    say STDERR 'In PROLOG handler';
                    say STDERR 'LITERAL: ', ${ $Marpa::UrHTML::LITERAL };
                    say STDERR 'LITERAL: ', ${ (eval { $Marpa::UrHTML::LITERAL}) };
                    my $literal = Marpa::UrHTML::literal() // q{};
                    return "PROLOG:\n" . ${$literal} . "\n";
                    }
            ],
            [   'ROOT' => sub {
                    say STDERR 'In ROOT handler';
                    say STDERR 'LITERAL: ', ${ $Marpa::UrHTML::LITERAL };
                    say STDERR 'LITERAL: ', ${ (eval { $Marpa::UrHTML::LITERAL}) };
                    my $literal = Marpa::UrHTML::literal() // q{};
                    return "ROOT:\n" . ${$literal} . "\n";
                    }
            ],
        ],
        trace_cruft => 1,
    }
);
my $value = $p->parse( \$document );

say Data::Dumper::Dumper($value);

# Marpa::Test::is( ${ ${$value} }, $no_tang_document, 'remove kTang class' );
