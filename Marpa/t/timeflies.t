#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use lib 'lib';
use lib 't/lib';
use English qw( -no_match_vars );

use Test::More tests => 5;
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $grammar_description='
start symbol is englishsentence.
semantics are perl5.  version is 0.001_015.
default lex prefix is /\s+|\A/.
concatenate lines is q{ (scalar @_) ? (join "-", (grep { $_ } @_)) : undef; }.
default action is concatenate lines.

englishsentence: subject, verb, conjunction, object.
    q{ "svco(" . join(";", @_) . ")" }.

englishsentence: subject, verb, object.
    q{ "svo(" . join(";", @_) . ")" }.

specializernoun: noun.  q{ "specializernoun($_[0])" }.

ordinarynoun: noun.  q{ "ordinarynoun($_[0])" }.

subject: specializernoun, ordinarynoun.  q{ "spsub($_[0]+$_[1])" }.

subject: noun.  q{ "subject($_[0])" }.

noun: nounlex.

nounlex matches /fruit|banana|time|arrow|flies/.

verb: verblex.  q{ "verb($_[0])" }.

verblex matches /like|flies/.

object: article, noun.  q{ "ob(prep($_[0])+n($_[1]))" }.

conjunction: /like/.  q{ "conjunction($_[0])" }.

article: articlelex.

articlelex matches /a\b|an/.

';

my $data1 = 'time flies like an arrow.';
my $data2 = 'fruit flies like a banana.';
my $grammar =
    Marpa::Grammar->new( { mdl_source => \$grammar_description, strip => 0 } );
my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

my $fail_offset = $recce->text($data1);
if ( $fail_offset >= 0 ) {
        Carp::croak("Parse failed at offset $fail_offset");
}
$recce->end_input();
say $grammar->show_QDFA();
say $recce->show_earley_sets();

my $evaler = Marpa::Evaluator->new( { recognizer => $recce, clone => 0, trace_evaluation => 1 } );
Carp::croak('Parse failed') unless $evaler;
say $evaler->show_bocage(99);

my $i = -1;
while ( defined( my $value = $evaler->value() ) ) {
    say "=====";
    say ${$value};
    say $evaler->show_tree(99);
    say q{};
}
