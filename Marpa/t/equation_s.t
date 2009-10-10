#!perl
# An ambiguous equation

use 5.010;
use strict;
use warnings;
use lib 'lib';
use English qw( -no_match_vars );
use Fatal qw(open close chdir);
use Carp;

use Test::More tests => 7;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
    Test::More::use_ok('Marpa::MDLex');
}

# The inefficiency (at least some of it) is deliberate.
# Passing up a duples of [ string, value ] and then
# assembling a final string at the top would be better
# than assembling the string then taking it
# apart at each step.  But I wanted to test having
# a start symbol that appears repeatedly on the RHS.

my $example_dir = 'example';
chdir $example_dir;

use example::equation;

open my $grammar_fh, q{<}, 'equation.marpa';
my $source;
{ local ($RS) = undef; $source = <$grammar_fh> };
close $grammar_fh;

# Set max_parses to 10 in case there's an infinite loop.
# This is for debugging, after all
my $grammar = Marpa::Grammar->new(
    {   actions    => 'Marpa::Example::Equation',
        max_parses => 10,
        self_arg   => 1,
        mdl_source => \$source,
    }
);

Carp::croak('Failed to create grammar') if not defined $grammar;

my $lexer_args = $grammar->lexer_args();

$grammar->precompute();

my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
my $lexer = Marpa::MDLex->new( { recce => $recce, %{$lexer_args} } );

my $fail_offset = $lexer->text('2-0*3+1');
if ( $fail_offset >= 0 ) {
    Marpa::exception("Parse failed at offset $fail_offset");
}

$recce->end_input();

my %expected_value = (
    '(2-(0*(3+1)))==2' => 1,
    '(((2-0)*3)+1)==7' => 1,
    '((2-(0*3))+1)==3' => 1,
    '((2-0)*(3+1))==8' => 1,
    '(2-((0*3)+1))==1' => 1,
);

# Note: code below used in display
my $evaler = Marpa::Evaluator->new( { recognizer => $recce } );
Marpa::exception('Parse failed') if not $evaler;

my $i = 0;
while ( defined( my $value = $evaler->value() ) ) {
    my $value = ${$value};
    Test::More::ok( $expected_value{$value}, "Value $i (unspecified order)" );
    delete $expected_value{$value};
    $i++;
} ## end while ( defined( my $value = $evaler->value() ) )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
