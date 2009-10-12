# This file was automatically generated using Marpa 0.001_019
#!perl
# This is the beginning of bootstrap_header.pl

## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (RegularExpressions::RequireDotMatchAnything)

use 5.010;
use strict;
use warnings;
use Marpa;
use Marpa::MDL;
use Marpa::MDL::Internal::New_Actions;
use Marpa::MDLex;
use Fatal qw(open close);
use English qw( -no_match_vars ) ;

my $new_terminals = [];
my $new_rules = [];
my $new_start_symbol;
my $new_semantics;
my $new_version;
my $new_default_action;
my $new_default_null_value;
my $new_default_lex_prefix;
my %strings;

sub usage {
   Marpa::exception("usage: $0 grammar-file\n");
}

my $argc = @ARGV;
usage() if $argc < 1 or $argc > 3;

my $grammar_file_name = shift @ARGV;
my $header_file_name = shift @ARGV;
my $trailer_file_name = shift @ARGV;

# This is the end of bootstrap_header.pl
$new_semantics = 'perl5';

$new_version = '0.001_019';

$new_start_symbol = 'grammar';

$new_default_lex_prefix = "\(\?\:\[\ \\t\]\*\(\?\:\\n\|\(\?\:\\\#\[\^\\n\]\*\\n\)\)\)\*\[\ \\t\]\*";

push @{$new_rules}, {
    lhs => 'grammar'
,    rhs => ['paragraphs', 'trailing-matter'],
    action =>'grammar',
,
,

};
push @{$new_rules}, {
    lhs => 'paragraphs'
,rhs => ['paragraph'],
separator => 'empty-line',
min => 1,
,
,
,

};
push @{$new_rules}, {
    lhs => 'paragraph'
,    rhs => ['definition-paragraph'],
,
,

};
push @{$new_rules}, {
    lhs => 'paragraph'
,    rhs => ['production-paragraph'],
,
,

};
push @{$new_rules}, {
    lhs => 'paragraph'
,    rhs => ['terminal-paragraph'],
,
,

};
push @{$new_rules}, {
    lhs => 'definition-paragraph'
,rhs => ['definition'],
min => 1,
,
,
,

};
push @{$new_rules}, {
    lhs => 'production-paragraph'
,    rhs => ['non-structural-production-sentences', 'production-sentence', 'non-structural-production-sentences', 'action-sentence:optional', 'non-structural-production-sentences'],
    action =>'production_paragraph',
,
,

};
push @{$new_rules},
    { lhs => 'action-sentence:optional',  rhs => [ 'action-sentence' ],  action => 'Marpa::MDL::Internal::New_Actions::first_arg'},
    { lhs => 'action-sentence:optional',  rhs => [], },
 ;

push @{$new_rules}, {
    lhs => 'non-structural-production-sentences'
,rhs => ['non-structural-production-sentence'],
min => 0,
,
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'non-structural-production-sentence'
,    rhs => ['priority:k0', 'integer', 'period'],
    action =>'non_structural_production_sentence',
,
,

};
push @{$new_terminals},
    ['priority:k0' => { regex => "priority" }],
;

push @{$new_rules}, {
    lhs => 'action-sentence'
,    rhs => ['the:k1:optional', 'action:k2', 'is:k3', 'action-specifier', 'period'],
    action =>'long_action_sentence',
,
,

};
push @{$new_terminals},
    ['the:k1' => { regex => "the" }],
    ['action:k2' => { regex => "action" }],
    ['is:k3' => { regex => "is" }],
;

push @{$new_rules},
    { lhs => 'the:k1:optional',  rhs => [ 'the:k1' ],  action => 'Marpa::MDL::Internal::New_Actions::first_arg'},
    { lhs => 'the:k1:optional',  rhs => [], },
 ;

push @{$new_rules}, {
    lhs => 'action-sentence'
,    rhs => ['action-specifier', 'period'],
    action =>'short_action_sentence',
,
,

};
push @{$new_rules}, {
    lhs => 'action-specifier'
,    rhs => ['string-specifier'],
    action =>'first_arg',
,
,

};
push @{$new_rules}, {
    lhs => 'non-structural-production-sentence'
,    rhs => ['comment-sentence'],
,
,

};
push @{$new_rules}, {
    lhs => 'non-structural-terminal-sentence'
,    rhs => ['comment-sentence'],
,
,

};
push @{$new_rules}, {
    lhs => 'definition'
,    rhs => ['predefined-setting', 'period'],
    action =>'definition_of_predefined',
,
,
 priority => 1000
};
push @{$new_rules}, {
    lhs => 'definition'
,    rhs => ['comment-sentence'],
,
,

};
push @{$new_rules}, {
    lhs => 'definition'
,    rhs => ['bracketed-comment'],
,
,

};
push @{$new_rules}, {
    lhs => 'definition'
,    rhs => ['string-definition'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['default-action-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['default-null-value-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['semantics-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['version-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['start-symbol-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'predefined-setting'
,    rhs => ['default-lex-prefix-setting'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'semantics-setting'
,    rhs => ['the:k1:optional', 'semantics:k4', 'copula', 'perl5:k5'],
    action =>'semantics_predicate',
,
,

};
push @{$new_terminals},
    ['semantics:k4' => { regex => "semantics" }],
    ['perl5:k5' => { regex => "perl5" }],
;

push @{$new_rules}, {
    lhs => 'semantics-setting'
,    rhs => ['perl5:k5', 'copula', 'the:k1:optional', 'semantics:k4'],
    action =>'semantics_subject',
,
,

};
push @{$new_rules}, {
    lhs => 'version-setting'
,    rhs => ['the:k1:optional', 'version:k6', 'copula', 'version-number'],
    action =>'version_predicate',
,
,

};
push @{$new_terminals},
    ['version:k6' => { regex => "version" }],
;

push @{$new_rules}, {
    lhs => 'version-setting'
,    rhs => ['version%5c%20number:k7', 'copula', 'the:k1:optional', 'version:k6'],
    action =>'version_subject',
,
,

};
push @{$new_terminals},
    ['version%5c%20number:k7' => { regex => "version\ number" }],
;

push @{$new_rules}, {
    lhs => 'start-symbol-setting'
,    rhs => ['the:k1:optional', 'start:k8', 'symbol:k9', 'copula', 'symbol-phrase'],
    action =>'start_symbol_predicate',
,
,

};
push @{$new_terminals},
    ['start:k8' => { regex => "start" }],
    ['symbol:k9' => { regex => "symbol" }],
;

push @{$new_rules}, {
    lhs => 'start-symbol-setting'
,    rhs => ['symbol-phrase', 'copula', 'the:k1:optional', 'start:k8', 'symbol:k9'],
    action =>'start_symbol_subject',
,
,

};
push @{$new_rules}, {
    lhs => 'default-lex-prefix-setting'
,    rhs => ['regex', 'copula', 'the:k1:optional', 'default:ka', 'lex:kb', 'prefix:kc'],
    action =>'default_lex_prefix_subject',
,
,

};
push @{$new_terminals},
    ['default:ka' => { regex => "default" }],
    ['lex:kb' => { regex => "lex" }],
    ['prefix:kc' => { regex => "prefix" }],
;

push @{$new_rules}, {
    lhs => 'default-lex-prefix-setting'
,    rhs => ['the:k1:optional', 'default:ka', 'lex:kb', 'prefix:kc', 'copula', 'regex'],
    action =>'default_lex_prefix_predicate',
,
,

};
push @{$new_rules}, {
    lhs => 'default-null-value-setting'
,    rhs => ['string-specifier', 'copula', 'the:k1:optional', 'default:ka', 'null:kd', 'value:ke'],
    action =>'default_null_value_subject',
,
,

};
push @{$new_terminals},
    ['null:kd' => { regex => "null" }],
    ['value:ke' => { regex => "value" }],
;

push @{$new_rules}, {
    lhs => 'default-null-value-setting'
,    rhs => ['the:k1:optional', 'default:ka', 'null:kd', 'value:ke', 'copula', 'string-specifier'],
    action =>'default_null_value_predicate',
,
,

};
push @{$new_rules}, {
    lhs => 'copula'
,    rhs => ['is:k3'],
,
,

};
push @{$new_rules}, {
    lhs => 'copula'
,    rhs => ['are:kf'],
,
,

};
push @{$new_terminals},
    ['are:kf' => { regex => "are" }],
;

push @{$new_rules}, {
    lhs => 'string-definition'
,    rhs => ['symbol-phrase', 'is:k3', 'string-specifier', 'period'],
    action =>'string_definition',
,
,

};
push @{$new_rules}, {
    lhs => 'default-action-setting'
,    rhs => ['action-specifier', 'is:k3', 'the:k1:optional', 'default:ka', 'action:k2'],
    action =>'default_action_subject',
,
,

};
push @{$new_rules}, {
    lhs => 'default-action-setting'
,    rhs => ['the:k1:optional', 'default:ka', 'action:k2', 'is:k3', 'action-specifier'],
    action =>'default_action_predicate',
,
,

};
push @{$new_rules}, {
    lhs => 'comment-sentence'
,    rhs => ['comment-tag', '%5c%3a:k10', 'comment-words', 'period'],
,
,

};
push @{$new_terminals},
    ['%5c%3a:k10' => { regex => "\:" }],
;

push @{$new_rules}, {
    lhs => 'comment-words'
,rhs => ['comment-word'],
min => 1,
,
,
,

};
push @{$new_rules}, {
    lhs => 'literal-string'
,    rhs => ['q-string'],
    action =>'q_string',
,
,

};
push @{$new_rules}, {
    lhs => 'literal-string'
,    rhs => ['double-quoted-string'],
    action =>'literal_string',
,
,

};
push @{$new_rules}, {
    lhs => 'literal-string'
,    rhs => ['single-quoted-string'],
    action =>'literal_string',
,
,

};
push @{$new_rules}, {
    lhs => 'production-sentence'
,    rhs => ['lhs', 'production-copula', 'rhs', 'period'],
    action =>'production_sentence',
,
,

};
push @{$new_rules}, {
    lhs => 'production-copula'
,    rhs => ['%5c%3a:k10'],
,
,

};
push @{$new_rules}, {
    lhs => 'production-copula'
,    rhs => ['%5c%3a%5c%3a%5c%3d:k11'],
,
,

};
push @{$new_terminals},
    ['%5c%3a%5c%3a%5c%3d:k11' => { regex => "\:\:\=" }],
;

push @{$new_rules}, {
    lhs => 'symbol-phrase'
,rhs => ['symbol-word'],
min => 1,
,
    action =>'symbol_phrase',
,
,

};
push @{$new_rules}, {
    lhs => 'lhs'
,    rhs => ['symbol-phrase'],
    action =>'lhs',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs'
,    rhs => [],
    action =>'empty_rhs',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs'
,rhs => ['rhs-element'],
separator => 'comma',
min => 1,
,
    action =>'comma_separated_rhs',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs'
,    rhs => ['symbol-phrase', 'sequence:k12'],
    action =>'sequence_rhs',
,
,
 priority => 1000
};
push @{$new_terminals},
    ['sequence:k12' => { regex => "sequence" }],
;

push @{$new_rules}, {
    lhs => 'rhs'
,    rhs => ['optional:k13', 'symbol-phrase', 'sequence:k12'],
    action =>'optional_sequence_rhs',
,
 priority => 2000,

};
push @{$new_terminals},
    ['optional:k13' => { regex => "optional" }],
;

push @{$new_rules}, {
    lhs => 'rhs'
,    rhs => ['symbol-phrase', 'separated:k14', 'symbol-phrase', 'sequence:k12'],
    action =>'separated_sequence_rhs',
,
 priority => 2000,

};
push @{$new_terminals},
    ['separated:k14' => { regex => "separated" }],
;

push @{$new_rules}, {
    lhs => 'rhs'
,    rhs => ['optional:k13', 'symbol-phrase', 'separated:k14', 'symbol-phrase', 'sequence:k12'],
    action =>'optional_separated_sequence_rhs',
,
 priority => 3000,

};
push @{$new_rules}, {
    lhs => 'rhs-element'
,    rhs => ['mandatory-rhs-element'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs-element'
,    rhs => ['optional-rhs-element'],
    action =>'concatenate_lines',
,
 priority => 1000,

};
push @{$new_rules}, {
    lhs => 'mandatory-rhs-element'
,    rhs => ['rhs-symbol-specifier'],
    action =>'mandatory_rhs_element',
,
,

};
push @{$new_rules}, {
    lhs => 'optional-rhs-element'
,    rhs => ['optional:k13', 'rhs-symbol-specifier'],
    action =>'optional_rhs_element',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs-symbol-specifier'
,    rhs => ['symbol-phrase'],
    action =>'rhs_symbol_phrase_specifier',
,
,

};
push @{$new_rules}, {
    lhs => 'rhs-symbol-specifier'
,    rhs => ['regex'],
    action =>'rhs_regex_specifier',
,
,

};
push @{$new_rules}, {
    lhs => 'terminal-paragraph'
,    rhs => ['non-structural-terminal-sentences', 'terminal-sentence', 'non-structural-terminal-sentences'],
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'non-structural-terminal-sentences'
,rhs => ['non-structural-terminal-sentence'],
min => 0,
,
    action =>'concatenate_lines',
,
,

};
push @{$new_rules}, {
    lhs => 'terminal-sentence'
,    rhs => ['symbol-phrase', 'matches:k15', 'regex', 'period'],
    action =>'regex_terminal_sentence',
,
,

};
push @{$new_terminals},
    ['matches:k15' => { regex => "matches" }],
;

push @{$new_rules}, {
    lhs => 'terminal-sentence'
,    rhs => ['match:k16', 'symbol-phrase', 'using:k17', 'string-specifier', 'period'],
    action =>'string_terminal_sentence',
,
,

};
push @{$new_terminals},
    ['match:k16' => { regex => "match" }],
    ['using:k17' => { regex => "using" }],
;

push @{$new_rules}, {
    lhs => 'string-specifier'
,    rhs => ['literal-string'],
    action =>'first_arg',
,
,

};
push @{$new_rules}, {
    lhs => 'string-specifier'
,    rhs => ['symbol-phrase'],
    action =>'string_name_specifier',
,
,

};
push @{$new_terminals}, [ 'q-string' => { action =>'lex_q_quote'} ];

push @{$new_terminals}, [ 'regex' => { action =>'lex_regex'} ];

push @{$new_terminals}, [ 'empty-line' => { regex => "\^\\h\*\\n"} ] ;

push @{$new_rules}, {
    lhs => 'trailing-matter'
,    rhs => ['final-comment'],
,
,

};
push @{$new_rules}, {
    lhs => 'trailing-matter'
,    rhs => ['final-whitespace'],
,
,

};
push @{$new_rules}, {
    lhs => 'trailing-matter'
,    rhs => [],
,
,

};
push @{$new_terminals}, [ 'final-comment' => { regex => "\\\#\[\^\\n\]\*\\Z"} ] ;

push @{$new_terminals}, [ 'final-whitespace' => { regex => "\\s\\z"} ] ;

push @{$new_terminals}, [ 'bracketed-comment' => { regex => "\\x\{5b\}\[\^\\x\{5d\}\]\*\\x\{5d\}"} ] ;

push @{$new_terminals}, [ 'single-quoted-string' => { action =>'lex_single_quote'} ];

push @{$new_terminals}, [ 'double-quoted-string' => { action =>'lex_double_quote'} ];

push @{$new_terminals}, [ 'version-number' => { regex => "\\d\+\\\.\[\\d_\.\]\+\\d"} ] ;

push @{$new_terminals}, [ 'symbol-word' => { regex => "\[a\-zA\-Z_\]\[a\-zA\-Z0\-9_\-\]\*"} ] ;

push @{$new_terminals}, [ 'period' => { regex => "\\\."} ] ;

push @{$new_terminals}, [ 'integer' => { regex => "\\d\+"} ] ;

push @{$new_terminals}, [ 'comment-tag' => { regex => "\(to\\s\+do\|note\|comment\)"} ] ;

push @{$new_terminals}, [ 'comment-word' => { regex => "\[\\x\{21\}\-\\x\{2d\}\\x\{2f\}\-\\x\{7e\}\]\+"} ] ;

push @{$new_terminals}, [ 'comma' => { regex => "\\\,"} ] ;

# This is the beginning of bootstrap_trailer.pl

$new_start_symbol //= '(undefined start symbol)';
$new_semantics //= 'not defined';
$new_version //= 'not defined';

Marpa::exception('Version requested is ', $new_version, "\nVersion must match ", $Marpa::VERSION, ' exactly.')
   unless $new_version eq $Marpa::VERSION;

Marpa::exception('Semantics are ', $new_semantics, "\nThe only semantics currently available are perl5.")
   unless $new_semantics eq 'perl5';

my $g = new Marpa::Grammar(
    {   start     => $new_start_symbol,
        rules     => $new_rules,
        terminals => $new_terminals,
        warnings  => 1,
        action_object => 'Marpa::MDL::Internal::New_Actions',
    }
);

$g->set( { default_lex_prefix => $new_default_lex_prefix, } )
    if defined $new_default_lex_prefix;

$g->set( { default_action => $new_default_action, } )
    if defined $new_default_action;

$g->set( { default_null_value => $new_default_null_value, } )
    if defined $new_default_null_value;

$g->precompute();

my $lexer_args = $g->lexer_args();

my $recce = new Marpa::Recognizer({
   grammar=> $g,
});

my $lexer = Marpa::MDLex->new( { recce => $recce, %{$lexer_args} } );

sub locator {
    my $earleme = shift;
    my $string = shift;

    state $lines;
    $lines = [0];
    my $pos = pos ${$string} = 0;
    NL: while (${$string} =~ /\n/gxms) {
	$pos = pos ${$string};
	push @{$lines}, $pos;
	last NL if $pos > $earleme;
    }
    my $line = (@{$lines}) - ($pos > $earleme ? 2 : 1);
    my $line_start = $lines->[$line];
    return ($line, $line_start);
}

my $spec;

{
    local($RS) = undef;
    open my $grammar, '<', $grammar_file_name or Marpa::exception("Cannot open $grammar_file_name: $ERRNO");
    $spec = <$grammar>;
    close $grammar;
    if ((my $earleme = $lexer->text(\$spec)) >= 0) {
	# for the editors, line numbering starts at 1
	# do something about this?
	my ($line, $line_start) = locator($earleme, \$spec);
	say STDERR 'Parsing exhausted at line ', $line+1, ", earleme $earleme";
	given (index $spec, "\n", $line_start) {
	    when (undef) { say STDERR substr $spec, $line_start }
	    default { say STDERR substr $spec, $line_start, $_-$line_start }
	}
	say STDERR +(q{ } x ($earleme-$line_start)), q{^};
	exit 1;
    }
}

$recce->end_input();

my $evaler = new Marpa::Evaluator( { recce => $recce } );
Marpa::exception('No parse') unless $evaler;

sub slurp {
    open my $fh, '<', shift;
    local($RS)=undef;
    my $file = <$fh>;
    close $fh;
    return $file;
}

say '# This file was automatically generated using Marpa ', $Marpa::VERSION;

if ($header_file_name)
{
    my $header = slurp($header_file_name);
    if (defined $header)
    {
        # explicit STDOUT is workaround for perlcritic bug
        print {*STDOUT} $header
            or Marpa::exception("print failed: $ERRNO");
    }
}

my $value = $evaler->value();
say ${$value};

if ($trailer_file_name)
{
    my $trailer = slurp($trailer_file_name);
    if (defined $trailer)
    {
        # explicit STDOUT is workaround for perlcritic bug
        print {*STDOUT} $trailer
            or Marpa::exception("print failed: $ERRNO");
    }
}

# This is the end of bootstrap_trailer.pl
