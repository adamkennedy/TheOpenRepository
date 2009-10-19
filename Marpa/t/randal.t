#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use lib 'lib';
use English qw( -no_match_vars );

use Test::More tests => 5;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::MDLex');
}

package Test_Grammar;

$Test_Grammar::marpa_options = [
    {
      'rules' => [
        {
          'action' => 'comment',
          'lhs' => 'comment:optional',
          'rhs' => [
            'comment'
          ]
        },
        {
          'lhs' => 'comment:optional',
          'rhs' => []
        },
        {
          'action' => 'show_perl_line',
          'lhs' => 'perl-line',
          'rhs' => [
            'perl-statements',
            'comment:optional'
          ]
        },
        {
          'action' => 'show_statement_sequence',
          'lhs' => 'perl-statements',
          'min' => 1,
          'rhs' => [
            'perl-statement'
          ],
          'separator' => 'semicolon'
        },
        {
          'action' => 'show_division',
          'lhs' => 'perl-statement',
          'rhs' => [
            'division'
          ]
        },
        {
          'action' => 'show_function_call',
          'lhs' => 'perl-statement',
          'rhs' => [
            'function-call'
          ]
        },
        {
          'action' => 'show_die',
          'lhs' => 'perl-statement',
          'rhs' => [
            'die:k0',
            'string-literal'
          ]
        },
        {
          'lhs' => 'division',
          'rhs' => [
            'expr',
            'division-sign',
            'expr'
          ]
        },
        {
          'lhs' => 'expr',
          'rhs' => [
            'function-call'
          ]
        },
        {
          'lhs' => 'expr',
          'rhs' => [
            'number'
          ]
        },
        {
          'action' => 'show_unary',
          'lhs' => 'function-call',
          'rhs' => [
            'unary-function-name',
            'argument'
          ]
        },
        {
          'action' => 'show_nullary',
          'lhs' => 'function-call',
          'rhs' => [
            'nullary-function-name'
          ]
        },
        {
          'lhs' => 'argument',
          'rhs' => [
            'pattern-match'
          ]
        }
      ],
      'start' => 'perl-line',
      'terminals' => [
        'die:k0',
        'unary-function-name',
        'nullary-function-name',
        'number',
        'semicolon',
        'division-sign',
        'pattern-match',
        'comment',
        'string-literal'
      ],
    }
  ];

$Test_Grammar::mdlex_options = [
    {   'default_prefix' => '\\s*',
        'terminals'      => [
            {   'name'  => 'die:k0',
                'regex' => 'die'
            },
            {   'name'  => 'unary-function-name',
                'regex' => '(caller|eof|sin|localtime)'
            },
            {   'name'  => 'nullary-function-name',
                'regex' => '(caller|eof|sin|time|localtime)'
            },
            {   'name'  => 'number',
                'regex' => '\\d+'
            },
            {   'name'  => 'semicolon',
                'regex' => ';'
            },
            {   'name'  => 'division-sign',
                'regex' => '[/]'
            },
            {   'name'  => 'pattern-match',
                'regex' => '[/][^/]*/'
            },
            {   'name'  => 'comment',
                'regex' => '[#].*'
            },
            {   'name'  => 'string-literal',
                'regex' => '"[^"]*"'
            }
        ]
    }
];

package main;

my @test_data = (
    [   'sin',
        q{sin  / 25 ; # / ; die "this dies!"},
        [ 'sin function call, die statement', 'division, comment' ]
    ],
    [ 'time', q{time  / 25 ; # / ; die "this dies!"}, ['division, comment'] ]
);

my $g = Marpa::Grammar->new(
    {   warnings   => 1,
        code_lines => -1,
        actions    => 'main',
    },
    @{$Test_Grammar::marpa_options}
);

$g->precompute();

TEST: for my $test_data (@test_data) {

    my ( $test_name, $test_input, $test_results ) = @{$test_data};
    my $recce = Marpa::Recognizer->new( { grammar => $g } );
    my $lexer = Marpa::MDLex->new( { recce => $recce },
        @{$Test_Grammar::mdlex_options} );
    $lexer->text( \$test_input );
    $recce->end_input();

    my $evaler = Marpa::Evaluator->new(
        { recce => $recce } );
    my @parses;
    while ( defined( my $value = $evaler->value ) ) {
        push @parses, ${$value};
    }
    my @expected_parses;
    my $expected_parse_count = scalar @{$test_results};
    my $parse_count          = scalar @parses;
    Marpa::Test::is( $parse_count, $expected_parse_count,
        "$test_name: Parse count" );

    my $expected = join "\n", @{$test_results};
    my $actual   = join "\n", @parses;
    Marpa::Test::is( $actual, $expected, "$test_name: Parse match" );
} ## end for my $test_data (@test_data)

## no critic (Subroutines::RequireArgUnpacking)

sub show_perl_line {
    shift;
    return join ', ', grep { defined } @_;
} ## end sub show_perl_line

sub comment                 { return 'comment' }
sub show_statement_sequence { shift; return join q{, }, @_ }
sub show_division           { return 'division' }
sub show_function_call      { return $_[1] }
sub show_die                { return 'die statement' }
sub show_unary   { return $_[1] . ' function call' }
sub show_nullary { return $_[1] . ' function call' }

## use critic
