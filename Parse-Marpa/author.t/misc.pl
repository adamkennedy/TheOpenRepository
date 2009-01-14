#!perl

use 5.010;
use strict;
use warnings;
use Parse::Marpa;

# This is code to test examples, in order to prove that they do actually
# compile and execute.  No checking other than for compilation errors
# or fatal exceptions is done.  This code DOES NOT do anything sensible.

my $mdl_source = <<'END';
semantics are perl5.
version is 1.001_003.
start symbol is S.

S: Document.

Document: .

END

my $trace_fh;
my $location;
my $first_result;
my @all_results;

my $grammar = new Parse::Marpa::Grammar();

$grammar->set({mdl_source => \$mdl_source});

my $cloned_grammar = $grammar->clone();

my $stringified_grammar = $grammar->stringify();

$grammar = Parse::Marpa::Grammar::unstringify($stringified_grammar, $trace_fh);

$grammar = Parse::Marpa::Grammar::unstringify($stringified_grammar);

my $new_lex_preamble = q{1};

my $recce = new Parse::Marpa::Recognizer({
   grammar=> $grammar,
   lex_preamble => $new_lex_preamble,
});

$recce->end_input();

my $stringified_recce = $recce->stringify();

$recce = Parse::Marpa::Recognizer::unstringify($stringified_recce, $trace_fh);

$recce = Parse::Marpa::Recognizer::unstringify($stringified_recce);

my $cloned_recce = $recce->clone();

my $evaler = new Parse::Marpa::Evaluator( {
    recce => $recce,
    end => $location,
    clone => 0,
} );

my $depth = 1;

$evaler->set( { cycle_depth => $depth } );

my $input_string = q{};
my $lexeme_start = 0;

{
    my ($regex, $token_length)
        = Parse::Marpa::Lex::lex_regex(\$input_string, $lexeme_start);
}

{
    my ($string, $token_length)
        = Parse::Marpa::Lex::lex_q_quote(\$input_string, $lexeme_start);
}

my $g = new Parse::Marpa::Grammar();

$g->set( {
    start => Parse::Marpa::MDL::canonical_symbol_name('Document')
} );

my $op = Parse::Marpa::MDL::get_symbol($grammar, 'Op');

my $grammar_description = $mdl_source;
my $string_to_parse = q{};

$first_result =
    Parse::Marpa::mdl( \$grammar_description, \$string_to_parse );

@all_results
    = Parse::Marpa::mdl(\$grammar_description, \$string_to_parse);

$first_result = Parse::Marpa::mdl(
    \$grammar_description,
    \$string_to_parse,
    { warnings => 0 }
);

