use 5.010;
use Parse::Marpa;

my $mdl_source = <<END;
semantics are perl5.
version is 0.219.1.
start symbol is S.

S: Document.

Document: .

END

my $grammar = new Parse::Marpa::Grammar();

$grammar->set({mdl_source => \$mdl_source});

my $stringified_grammar = $grammar->stringify();

$grammar = Parse::Marpa::Grammar::unstringify($stringified_grammar, $trace_fh);

$grammar = Parse::Marpa::Grammar::unstringify($stringified_grammar);

my $new_lex_preamble = q{};

my $recce = new Parse::Marpa::Recognizer({
   grammar=> $grammar,
   lex_preamble => $new_lex_preamble,
});

$recce->end_input();

my $evaler = new Parse::Marpa::Evaluator( {
    recce => $recce,
    end => $location
} );

$evaler->set( { cycle_depth => $depth } );

my $string = q{};
my $lexeme_start = 0;

my ($regex, $token_length)
    = Parse::Marpa::Lex::lex_regex(\$string, $lexeme_start);

my ($string, $token_length)
    = Parse::Marpa::Lex::lex_q_quote(\$string, $lexeme_start);

my $g = new Parse::Marpa::Grammar();

$g->set( {
    start => Parse::Marpa::MDL::canonical_symbol_name("Document")
} );

my $op = Parse::Marpa::MDL::get_symbol($grammar, "Op");

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

