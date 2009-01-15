package Parse::Marpa::Internal;
use 5.010;

use warnings;
no warnings 'recursion';
use strict;
use integer;
use English qw( -no_match_vars );

package Parse::Marpa::Read_Only;

# perhaps a Perl critic bug here -- I can't turn off the
# complaint for Parse::Marpa::Read_Only package
# variables

## no critic (Variables::ProhibitPackageVars)
our $rule;
## use critic

package Parse::Marpa::Internal;

# Elements of the EARLEY ITEM structure
# Note that these are Earley items as modified by Aycock & Horspool, with QDFA states instead of
# LR(0) items.

use Parse::Marpa::Offset Earley_item =>
    # evaluator data
    qw(NAME STATE TOKENS LINKS),
    # temporary data
    qw(PARENT SET);

# We don't prune the Earley items because we want PARENT and SET
# around for debugging

# NAME   - unique string describing Earley item
# STATE  - the QDFA state
# PARENT - the number of the Earley set with the parent item(s)
# TOKENS - a list of the links from token scanning
# LINKS  - a list of the links from the completer step
# SET    - the set this item is in, for debugging

# Elements of the RECOGNIZER structure
use Parse::Marpa::Offset Recognizer =>
    # evaluator data
    qw(GRAMMAR EARLEY_SETS START_ITEM
        CURRENT_PARSE_SET DEFAULT_PARSE_SET),
    # temporary data
    qw(
        CURRENT_SET EARLEY_HASH FURTHEST_EARLEME EXHAUSTED
        PACKAGE LEXERS LEXABLES_BY_STATE LAST_COMPLETED_SET
    );

package Parse::Marpa::Internal::Recognizer;
use constant LAST_EVALUATOR_FIELD => Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET;
package Parse::Marpa::Internal;

# GRAMMAR            - the grammar used
# CURRENT_SET        - index of the first incomplete Earley set
# EARLEY_SETS        - the array of the Earley sets
# EARLEY_HASH        - hash of the Earley items
#                      to build the Earley sets
# CURRENT_PARSE_SET  - the set being taken as the end of
#                      parse for an evaluation
#                      only undef if there are no evaluation
#                      notations in the earley items
# START_ITEM         - the start item for the current evaluation
# FURTHEST_EARLEME   - last earley set with a token
# EXHAUSTED          - parse can't continue?
# EVALUATOR          - the current evaluator for this recognizer
# PACKAGE            - special "safe" namespace
# LEXERS             - an array, indexed by symbol id,
#                      of the lexer for each symbol
# LEXABLES_BY_STATE  - an array, indexed by QDFA state id,
#                      of the lexables belonging in it
# LAST_COMPLETED_SET - last earley set completed

package Parse::Marpa::Internal::Recognizer;

use Scalar::Util qw(weaken);
use Data::Dumper;
use English qw( -no_match_vars );

use Carp;
our @CARP_NOT = qw(
Parse::Marpa
Parse::Marpa::Evaluator
Parse::Marpa::Grammar
Parse::Marpa::Internal
Parse::Marpa::Internal::And_Node
Parse::Marpa::Internal::Earley_item
Parse::Marpa::Internal::Evaluator
Parse::Marpa::Internal::Evaluator::Rule
Parse::Marpa::Internal::Grammar
Parse::Marpa::Internal::Interface
Parse::Marpa::Internal::LR0_item
Parse::Marpa::Internal::Lex
Parse::Marpa::Internal::NFA
Parse::Marpa::Internal::Or_Node
Parse::Marpa::Internal::Or_Sapling
Parse::Marpa::Internal::Phase
Parse::Marpa::Internal::QDFA
Parse::Marpa::Internal::Recognizer
Parse::Marpa::Internal::Rule
Parse::Marpa::Internal::Source_Eval
Parse::Marpa::Internal::Source_Raw
Parse::Marpa::Internal::Symbol
Parse::Marpa::Internal::This
Parse::Marpa::Internal::Tree_Node
Parse::Marpa::Lex
Parse::Marpa::MDL
Parse::Marpa::Read_Only
Parse::Marpa::Recognizer
);

my $parse_number = 0;

sub set_lexers {

    my $grammar = shift;
    my $package = shift;

    my (
	$symbols,
	$symbol_hash,
	$QDFA,
	$tracing, $default_prefix,
        $default_suffix
    ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::QDFA,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
    ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_actions =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_ACTIONS];
    }

    my @lexers;
    $#lexers = $#{$symbols};

    SYMBOL: for my $ix ( 0 .. $#lexers ) {

        my $symbol = $symbols->[$ix];
        my ( $name, $regex, $action, $symbol_prefix, $symbol_suffix ) =
            @{$symbol}[
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::REGEX,
            Parse::Marpa::Internal::Symbol::ACTION,
            Parse::Marpa::Internal::Symbol::PREFIX,
            Parse::Marpa::Internal::Symbol::SUFFIX,
            ];

        if ( defined $regex ) {
            $lexers[$ix] = $regex;
            next SYMBOL;
        }

        my $prefix = $symbol_prefix // $default_prefix;
        $prefix = qr/$prefix/xms if defined $prefix;
        my $suffix = $symbol_suffix // $default_suffix;
        $suffix = qr/$suffix/xms if defined $suffix;

        given ($action) {
            when (undef) {;}    # do nothing
                                # Right now do nothing but find lex_q_quote
            when ('lex_q_quote') {
                $lexers[$ix] =
                    [ \&Parse::Marpa::Lex::lex_q_quote, $prefix, $suffix ];
            }
            when ('lex_regex') {
                $lexers[$ix] =
                    [ \&Parse::Marpa::Lex::lex_regex, $prefix, $suffix ];
            }
            default {
                my $code
		    = "sub {\n"
		    . '    my $STRING = shift;' . "\n"
		    . '    my $START = shift;' . "\n"
                    . '    package ' . $package . ";\n"
		    . q{    } . $action . ";\n"
		    . "    return\n"
		    . "}\n";

                if ($trace_actions) {
                    print {$trace_fh} 'Setting action for terminal ', $name,
                        " to\n", $code,
                        "\n"
		    or croak('Could not print to trace file');
                }

                my $closure;
                {
                    my $old_warn_handler = $SIG{__WARN__};
                    my @warnings;
                    $SIG{__WARN__} = sub { push @warnings, [ $_[0], (caller 0) ]; };

		    ## no critic (BuiltinFunctions::ProhibitStringyEval)
                    $closure = eval $code;
		    ## use critic

                    $SIG{__WARN__} = $old_warn_handler;

                    if ( not $closure or @warnings ) {
                        my $fatal_error = $EVAL_ERROR;
                        Parse::Marpa::Internal::code_problems({
                            eval_ok => $closure,
                            fatal_error => $fatal_error,
                            grammar => $grammar,
                            warnings => \@warnings,
                            where => 'compiling lexer',
                            long_where => "compiling lexer for $name",
                            code => \$code,
                        });
                    }
                }

                $symbol->[Parse::Marpa::Internal::Symbol::ACTION] = $code;
                $lexers[$ix] = [ $closure, $prefix, $suffix ];

            }
        }

    }    # SYMBOL

    my @lexables_by_state;
    $#lexables_by_state = $#{$QDFA};

    for my $state (@{$QDFA}) {
        my ( $id, $transition ) = @{$state}[
            Parse::Marpa::Internal::QDFA::ID,
            Parse::Marpa::Internal::QDFA::TRANSITION,
        ];
        $lexables_by_state[$id] = [
            grep { $lexers[$_] }
                map {
                $symbol_hash->{$_}->[Parse::Marpa::Internal::Symbol::ID]
                }
                keys %{$transition}
        ];
    }

    return ( \@lexers, \@lexables_by_state, );

} # sub set_lexers

sub compile_regexes {
    my $grammar = shift;
    my ( $symbols, $default_lex_prefix, $default_lex_suffix, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
    ];

    SYMBOL: for my $symbol (@{$symbols}) {
        my $regex = $symbol->[Parse::Marpa::Internal::Symbol::REGEX];
        next SYMBOL unless defined $regex;
        if ( q{} =~ $regex ) {
            my $name = $symbol->[Parse::Marpa::Internal::Symbol::NAME];
            croak( 'Attempt to add nullable terminal: ', $name );
        }
        my $prefix = $symbol->[Parse::Marpa::Internal::Symbol::PREFIX]
            // $default_lex_prefix;
        my $suffix = $symbol->[Parse::Marpa::Internal::Symbol::SUFFIX]
            // $default_lex_suffix;
        my $compiled_regex = qr{
            \G
            (?<mArPa_prefix>$prefix)
            (?<mArPa_match>$regex)
            (?<mArPa_suffix>$suffix)
        }xms;
        $symbol->[Parse::Marpa::Internal::Symbol::REGEX] = $compiled_regex;
    }    # SYMBOL

    return;

}

sub prepare_grammar_for_recognizer {
    my $parse   = shift;
    my $grammar = shift;

    local ($Data::Dumper::Terse) = 1;
    my $package = $parse->[Parse::Marpa::Internal::Recognizer::PACKAGE] =
        sprintf 'Parse::Marpa::P_%x', $parse_number++;

    my $lex_preamble = $grammar->[Parse::Marpa::Internal::Grammar::LEX_PREAMBLE];
    my $default_action =
        $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION];
    my $default_null_value =
        $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE];

    if ( defined $lex_preamble ) {
        my $old_warn_handler = $SIG{__WARN__};
        my @warnings;
        $SIG{__WARN__} = sub { push @warnings, [ $_[0], (caller 0) ]; };

        my $code =
	    'package ' . $package . ";\n"
	    . $lex_preamble;
	## no critic (BuiltinFunctions::ProhibitStringyEval)
        my $eval_ok = eval $code;
	## use critic

        $SIG{__WARN__} = $old_warn_handler;

        if (not $eval_ok or @warnings ) {
            my $fatal_error = $EVAL_ERROR;
            Parse::Marpa::Internal::code_problems({
                eval_ok => $eval_ok,
                fatal_error => $fatal_error,
                grammar => $grammar,
                warnings => \@warnings,
                where => 'evaluating lex preamble',
                code => \$code,
            });
        }
    }

    compile_regexes($grammar);
    @{$parse}[ LEXERS, LEXABLES_BY_STATE ] =
        set_lexers( $grammar, $package );

    return;

}

# Returns the new parse object or throws an exception
sub Parse::Marpa::Recognizer::new {
    my $class = shift;
    my $args = shift;

    my $arg_trace_fh = $args->{trace_file_handle};

    my $parse = [];
    my $ambiguous_lex;
    my $lex_preamble;

    my $clone_arg = $args->{clone};
    delete $args->{clone};
    my $clone = $clone_arg // 1;

    my $grammar = $args->{grammar};
    if ( not defined $grammar ) {
        my $stringified_grammar = $args->{stringified_grammar};
        croak('No grammar specified') unless defined $stringified_grammar;
        delete $args->{stringified_grammar};
        my $trace_fh = $arg_trace_fh // (*STDERR);
        $grammar =
            Parse::Marpa::Grammar::unstringify( $stringified_grammar, $trace_fh );
        $clone = 0;
    }
    else {
        delete $args->{grammar};
    }

    my $grammar_class = ref $grammar;
    croak("${class}::new() grammar arg has wrong class: $grammar_class")
        unless $grammar_class eq 'Parse::Marpa::Grammar';

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::Grammar::show_problems($grammar),
            "Attempt to parse grammar with fatal problems\n",
            'Marpa cannot proceed',
        );
    }

    if ( $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] ) {
        croak( "Attempt to parse grammar marked academic\n",
            'Marpa cannot proceed' );
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if (   $phase != Parse::Marpa::Internal::Phase::PRECOMPUTED )
    {
        croak(
            'Attempt to parse grammar in inappropriate phase ',
            Parse::Marpa::Internal::Phase::description($phase)
        );
    }

    if ( $clone) {
        $grammar = $grammar->clone($arg_trace_fh);
        delete $args->{trace_file_handle};
    }

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    # options are not set until *AFTER* the grammar is cloned
    Parse::Marpa::Grammar::set( $grammar, $args );

    prepare_grammar_for_recognizer( $parse, $grammar );

    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::RECOGNIZING;

    my $earley_hash;
    my $earley_set;

    my $start_states =
        $grammar->[Parse::Marpa::Internal::Grammar::START_STATES];

    for my $state (@{$start_states}) {
	my $state_id = $state->[Parse::Marpa::Internal::QDFA::ID];
        my $name = sprintf 'S%d@%d-%d', $state_id, 0, 0;
        my $item;
        @{$item}[
            Parse::Marpa::Internal::Earley_item::NAME,
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT,
            Parse::Marpa::Internal::Earley_item::TOKENS,
            Parse::Marpa::Internal::Earley_item::LINKS,
            Parse::Marpa::Internal::Earley_item::SET
            ]
            = ( $name, $state, 0, [], [], 0 );
        push @{$earley_set}, $item;
        $earley_hash->{$name} = $item;
    }

    @{$parse}[
        DEFAULT_PARSE_SET, CURRENT_SET, FURTHEST_EARLEME,
        EARLEY_HASH,     GRAMMAR,     EARLEY_SETS,
        LAST_COMPLETED_SET,
        ]
        = ( 0, 0, 0, $earley_hash, $grammar, [$earley_set], -1, );

    bless $parse, $class;
}

# Convert Recognizer into string form
#
sub Parse::Marpa::Recognizer::stringify {
    my $recce = shift;
    my $grammar = $recce->[ Parse::Marpa::Internal::Recognizer::GRAMMAR ];

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if (   $phase != Parse::Marpa::Internal::Phase::RECOGNIZED )
    {
        croak(
            "Attempt to stringify recognizer in inappropriate state\nAttempt to stringify ",
            Parse::Marpa::Internal::Phase::description($phase)
        );
    }

    my $d = Data::Dumper->new( [$recce], ['recce'] );
    $d->Purity(1);
    $d->Indent(0);

    # returns a ref -- dumps can be long
    return \( $d->Dump() );
}

# First arg is stringified recognizer
# Second arg (optional) is trace file handle, either saved and restored
# If not trace file handle supplied, it reverts to the default, STDERR
#
# Returns the unstringified recognizer
sub Parse::Marpa::Recognizer::unstringify {
    my $stringified_recce = shift;
    my $trace_fh         = shift;
    $trace_fh //= *STDERR;

    croak('Attempt to unstringify undefined recognizer')
        unless defined $stringified_recce;
    croak('Arg to unstringify must be ref to SCALAR')
        if ref $stringified_recce ne 'SCALAR';

    my $recce;
    {
        my $old_warn_handler = $SIG{__WARN__};
        my @warnings;
        $SIG{__WARN__} = sub { push @warnings, [ $_[0], (caller 0) ]; };

        ## no critic (BuiltinFunctions::ProhibitStringyEval,TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        my $eval_ok = eval ${$stringified_recce};
        use strict 'refs';
        ## use critic

        $SIG{__WARN__} = $old_warn_handler;

        if (not $eval_ok or @warnings ) {
            my $fatal_error = $EVAL_ERROR;
            Parse::Marpa::Internal::code_problems({
                eval_ok => $eval_ok,
                fatal_error => $fatal_error,
                warnings => \@warnings,
                where => 'unstringifying recognizer',
                code => $stringified_recce,
            });
        }
    }

    my $grammar = $recce->[ Parse::Marpa::Internal::Recognizer::GRAMMAR ];
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE] =
        $trace_fh;

    return $recce;

}

sub Parse::Marpa::Recognizer::clone {
    my $recce = shift;

    my $grammar = $recce->[Parse::Marpa::Internal::Recognizer::GRAMMAR];
    my $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];

    if ($#{$recce} > Parse::Marpa::Internal::Recognizer::LAST_EVALUATOR_FIELD)
    {
       croak(
           "Cloning of unstripped recognizers not yet implemented\n",
           "Strip the recognizer or turn off cloning\n"
        );
    }
    my $stringified_recce = Parse::Marpa::Recognizer::stringify($recce);
    # say $$stringified_recce;
    # exit 0;
    return Parse::Marpa::Recognizer::unstringify( $stringified_recce, $trace_fh );

}

# Viewing methods, for debugging
sub Parse::Marpa::brief_earley_item {
    my $item = shift;
    my $ii   = shift;
    return $item->[Parse::Marpa::Internal::Earley_item::NAME] unless $ii;
    my ( $state, $parent, $set ) = @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::PARENT,
        Parse::Marpa::Internal::Earley_item::SET
    ];
    my ( $id, $tag ) = @{$state}[
        Parse::Marpa::Internal::QDFA::ID,
        Parse::Marpa::Internal::QDFA::TAG
    ];
    my $text = defined $tag ? ( 'St' . $tag ) : ( 'S' . $id );
    $text .= q{@} . $parent . q{-} . $set;
    return $text;
}

sub show_token_choice {
    my $token = shift;
    my $ii    = shift;
    return '[p='
        . Parse::Marpa::brief_earley_item( $token->[0], $ii ) . '; t='
        . $token->[1] . ']';
}

sub show_link_choice {
    my $link = shift;
    my $ii   = shift;
    return '[p='
        . Parse::Marpa::brief_earley_item( $link->[0], $ii ) . '; c='
        . Parse::Marpa::brief_earley_item( $link->[1], $ii ) . ']';
}

sub Parse::Marpa::show_earley_item {
    my $item = shift;
    my $ii   = shift;
    my ($tokens,      $links) = @{$item}[
        Parse::Marpa::Internal::Earley_item::TOKENS,
        Parse::Marpa::Internal::Earley_item::LINKS,
    ];

    my $text = Parse::Marpa::brief_earley_item( $item, $ii );

    if ( defined $tokens and @{$tokens} ) {
        for my $token (@{$tokens}) {
            $text .= q{ } . show_token_choice( $token, $ii );
        }
    }
    if ( defined $links and @{$links} ) {
        for my $link (@{$links}) {
            $text .= q{ } . show_link_choice( $link, $ii );
        }
    }
    return $text;
}

sub Parse::Marpa::show_earley_set {
    my $earley_set = shift;
    my $ii         = shift;
    my $text       = q{};
    for my $earley_item (@{$earley_set}) {
        $text .= Parse::Marpa::show_earley_item( $earley_item, $ii ) . "\n";
    }
    return $text;
}

sub Parse::Marpa::show_earley_set_list {
    my $earley_set_list  = shift;
    my $ii               = shift;
    my $text             = q{};
    my $earley_set_count = @{$earley_set_list};
    LIST: for my $ix ( 0 .. $earley_set_count-1 ) {
        my $set = $earley_set_list->[$ix];
        next LIST unless defined $set;
        $text .= "Earley Set $ix\n"
            . Parse::Marpa::show_earley_set( $set, $ii );
    }
    return $text;
}

sub Parse::Marpa::Recognizer::show_earley_sets {
    my $recce = shift;
    my $ii    = shift;
    my $current_set = $recce->[ CURRENT_SET ];
    my $furthest_earleme = $recce->[ FURTHEST_EARLEME ];
    my $earley_set_list = $recce->[ EARLEY_SETS ];

    my $text = defined $furthest_earleme ?
          "Current Earley Set: $current_set; Furthest: $furthest_earleme\n" :
          "At End of Input\n";

    $text .= Parse::Marpa::show_earley_set_list( $earley_set_list, $ii );
    return $text;
}

# check class of parse?

## no critic (Subroutines::RequireArgUnpacking)
sub Parse::Marpa::Recognizer::earleme {
## use critic

    my $parse = shift;

    my $grammar = $parse->[Parse::Marpa::Internal::Recognizer::GRAMMAR];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if ($phase >= Parse::Marpa::Internal::Phase::RECOGNIZED) {
        croak('New earlemes not allowed after end of input');
    }

    # lexables not checked -- don't use prediction here
    # maybe add this as an option?
    my $lexables = Parse::Marpa::Internal::Recognizer::complete_set($parse);
    return Parse::Marpa::Internal::Recognizer::scan_set( $parse, @_ );
}

# Returns the position where parsing was exhausted,
# or -1 if parsing is not exhausted

# First arg is the current parse object
# Second arg is ref to string
sub Parse::Marpa::Recognizer::text {
    my $parse     = shift;
    my $input     = shift;
    my $input_length    = shift;
    croak(
        'Parse::Marpa::Recognizer::text() third argument not yet implemented')
        if defined $input_length;

    my $input_ref;
    given (ref $input) {
    when (q{}) { $input_ref = \$input; }
    when ('SCALAR') { $input_ref = $input; }
    default {
	croak(
	    'text argument to Parse::Marpa::Recognizer::text() ',
	    'must be string or string ref'
	);
    }
    } # given ref $input

    my ( $grammar, $earley_sets, $current_set, $lexers, ) = @{$parse}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
        Parse::Marpa::Internal::Recognizer::CURRENT_SET,
        Parse::Marpa::Internal::Recognizer::LEXERS,
    ];

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if ($phase >= Parse::Marpa::Internal::Phase::RECOGNIZED) {
        croak('More text not allowed after end of input');
    }

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    my $trace_lex_tries;
    my $trace_lex_matches;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_lex_tries =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES];
        $trace_lex_matches =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES];
    }

    my ( $symbols, $ambiguous_lex ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX,
    ];

    $input_length = length ${$input_ref} unless defined $input_length;

    pos ${$input_ref} = 0;
    POS: for my $pos (0 .. ($input_length-1)) {
        my @alternatives;

        # NOTE: Often the number of the earley set, and the idea of
        # lexical position will correspond.  Be careful that Marpa
        # imposes no such requirement, however.

        my $lexables = complete_set($parse);

        if ( $trace_lex_tries and scalar @{$lexables} ) {
            my $string_to_match = substr ${$input_ref}, $pos, 20;
            $string_to_match
                =~ s/([\x00-\x1F\x7F-\xFF])/sprintf('{%#.2x}', ord($1))/gexm;
            say $trace_fh "Match target at $pos: ", $string_to_match;
        }

        LEXABLE: for my $lexable (@{$lexables}) {
            my ($symbol_id) = @{$lexable}[Parse::Marpa::Internal::Symbol::ID];
            if ($trace_lex_tries) {
                print {$trace_fh} 'Trying to match ',
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos\n"
		or croak('Could not print to trace file');
            }

            my $lexer      = $lexers->[$symbol_id];
            my $lexer_type = ref $lexer;
            croak('Illegal type for lexer: undefined')
                unless defined $lexer_type;

            pos ${$input_ref} = $pos;

            if ( $lexer_type eq 'Regexp' ) {

		## no critic (RegularExpressions::RequireLineBoundaryMatching)
		## no critic (RegularExpressions::RequireExtendedFormatting)
                if ( ${$input_ref} =~ /$lexer/g ) {
		## use critic

		    ## no critic (Variables::ProhibitPunctuationVars)
                    my $match = $+{mArPa_match};
		    ## use critic

                    # my $prefix = $+{mArPa_prefix};
                    # my $suffix = $+{mArPa_suffix};
                    # my $length = length(${^MATCH});

                    my $length = ( pos ${$input_ref} ) - $pos;
                    croak(
                        'Internal error, zero length token -- this is a Marpa bug'
                    ) unless $length;
                    push @alternatives, [ $lexable, $match, $length ];
                    if ($trace_lex_matches) {
                        print {$trace_fh}
                            'Matched regex for ',
                            $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                            " at $pos: ", $match, "\n"
			or croak('Could not print to trace file');
                    }
                    last LEXABLE unless $ambiguous_lex;
                }    # if match

                next LEXABLE;

            }    # if defined regex

            # If it's a lexable and a regex was not defined, there must be a
            # closure
            croak("Illegal type for lexer: $lexer_type")
                unless $lexer_type eq 'ARRAY';

            my ( $lex_closure, $prefix, $suffix ) = @{$lexer};
            if ( defined $prefix ) {

		## no critic (RegularExpressions::RequireLineBoundaryMatching)
		## no critic (RegularExpressions::RequireExtendedFormatting)
                ${$input_ref} =~ /\G$prefix/g;
		## use critic

            }

            my ( $match, $length );
            {
                my $old_warn_handler = $SIG{__WARN__};
                my @warnings;
                $SIG{__WARN__} = sub { push @warnings, [ $_[0], (caller 0) ]; };

                my $eval_ok = eval {
                    ( $match, $length ) = $lex_closure->( $input_ref, $pos ); 1;
                };

                $SIG{__WARN__} = $old_warn_handler;

                if (not $eval_ok or @warnings ) {
                    my $fatal_error = $EVAL_ERROR;
                    Parse::Marpa::Internal::code_problems({
                        eval_ok => $eval_ok,
                        fatal_error => $fatal_error,
                        grammar => $grammar,
                        warnings => \@warnings,
                        where => 'user supplied lexer',
                        long_where => 'user supplied lexer for '
                            . $lexable->[Parse::Marpa::Internal::Symbol::NAME]
                            . " at $pos",
                        code => \(  $lexable->[Parse::Marpa::Internal::Symbol::ACTION] ),
                    });
                }
            }

            next LEXABLE if not defined $match;

            $length //= length $match;

            push @alternatives, [ $lexable, $match, $length ];
            if ($trace_lex_matches) {
                print {$trace_fh}
                    'Matched Closure for ',
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos: ", $match, "\n"
		or croak('Could not print to trace file');
            }

            last LEXABLE unless $ambiguous_lex;

        }    # LEXABLE

        my $active = scan_set( $parse, @alternatives );

        return $pos unless $active;

    }    # POS

    return -1;

}    # sub text

# Always returns success
sub Parse::Marpa::Recognizer::end_input {
    my $self = shift;

    my ( $grammar, $current_set, $last_completed_set, $furthest_earleme, ) =
        @{$self}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::CURRENT_SET,
        Parse::Marpa::Internal::Recognizer::LAST_COMPLETED_SET,
        Parse::Marpa::Internal::Recognizer::FURTHEST_EARLEME,
        ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    my $phase = $grammar->[ Parse::Marpa::Internal::Grammar::PHASE ];

    # If called repeatedly, just return success,
    # without complaint.  In other words, be idempotent.
    return 1 if $phase >= Parse::Marpa::Internal::Phase::RECOGNIZED;

    if ($last_completed_set < $furthest_earleme) {

         EARLEY_SET: while ( $current_set <= $furthest_earleme ) {
             Parse::Marpa::Internal::Recognizer::complete_set($self);
             $current_set++;
             $self->[Parse::Marpa::Internal::Recognizer::CURRENT_SET] =
                 $current_set;
         }

    }

    if ($grammar->[ Parse::Marpa::Internal::Grammar::STRIP ]) {

        $#{$self} = Parse::Marpa::Internal::Recognizer::LAST_EVALUATOR_FIELD;

        $#{$grammar} = Parse::Marpa::Internal::Grammar::LAST_EVALUATOR_FIELD;
        for my $symbol (@{$grammar->[ Parse::Marpa::Internal::Grammar::SYMBOLS ]}) {
            $#{$symbol} = Parse::Marpa::Internal::Symbol::LAST_EVALUATOR_FIELD;
        }
        for my $rule (@{$grammar->[ Parse::Marpa::Internal::Grammar::RULES ]}) {
            $#{$rule} = Parse::Marpa::Internal::Rule::LAST_EVALUATOR_FIELD;
        }
        for my $QDFA (@{$grammar->[ Parse::Marpa::Internal::Grammar::QDFA ]}) {
            $#{$QDFA} = Parse::Marpa::Internal::QDFA::LAST_EVALUATOR_FIELD;
        }

    }

    $grammar->[ Parse::Marpa::Internal::Grammar::PHASE ]
    = Parse::Marpa::Internal::Phase::RECOGNIZED;

    return 1;
}


# It's bad style, but this routine is in a tight loop -- it may be called
# as often as once per character of input in.  For efficiency
# I pull the token alternatives out of @_ one by one as I go in the code,
# rather than at the beginning of the method.

# The remaining arguments should be a list of token alternatives, as
# array references.  The array for each alternative is (token, value,
# length), where token is a symbol reference, value can anything
# meaningful to the user, and length is the length of this token in
# earlemes.

# Given a parse object and a list of alternative tokens starting at
# the current earleme, add Earley items to recognize those tokens.

## no critic (Subroutines::RequireArgUnpacking)
sub scan_set {
## use critic

    my $parse = shift;

    my ( $earley_set_list, $earley_hash, $grammar, $current_set,
        $furthest_earleme, $exhausted, )
        = @{$parse}[
        EARLEY_SETS,      EARLEY_HASH, GRAMMAR, CURRENT_SET,
        FURTHEST_EARLEME, EXHAUSTED
        ];
    croak('Attempt to scan tokens after parsing was exhausted') if $exhausted;
    my $QDFA = $grammar->[Parse::Marpa::Internal::Grammar::QDFA];

    my $earley_set = $earley_set_list->[$current_set];

    if ( not defined $earley_set ) {
        $earley_set_list->[$current_set] = [];
        if ( $current_set >= $furthest_earleme ) {
            $parse->[Parse::Marpa::Internal::Recognizer::EXHAUSTED] =
                $exhausted = 1;
        }
        else {
            $parse->[CURRENT_SET]++;
        }
        return !$exhausted;
    }

    # Important: more earley sets can be added in the loop
    my $earley_set_ix = -1;
    EARLEY_ITEM: while (1) {

        my $earley_item = $earley_set->[++$earley_set_ix];
        last EARLEY_ITEM unless defined $earley_item;

        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];

        # I allow ambigious tokenization.
        # Loop through the alternative tokens.
        ALTERNATIVE: for my $alternative (@_) {
            my ( $token, $value, $length ) = @{$alternative};

            if ( $length <= 0 ) {
                croak(    'Token '
                        . $token->[Parse::Marpa::Internal::Symbol::NAME]
                        . ' with bad length '
                        . $length );
            }

            # Make sure it's an allowed terminal symbol.
            # TODO: Must remember to be sure that
            # nulling symbols are never terminals
            unless ( $token->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
                my $name = $token->[Parse::Marpa::Internal::Symbol::NAME];
                croak(    'Non-terminal '
                        . ( defined $name ? "$name " : q{} )
                        . 'supplied as token' );
            }

            # compute goto(state, token_name)
            my $states =
                $QDFA->[ $state->[Parse::Marpa::Internal::QDFA::ID] ]
                ->[Parse::Marpa::Internal::QDFA::TRANSITION]
                ->{ $token->[Parse::Marpa::Internal::Symbol::NAME] };
            next ALTERNATIVE unless $states;

            # Create the kernel item and its link.
            my $target_ix   = $current_set + $length;
            my $target_set  = ( $earley_set_list->[$target_ix] //= [] );
            if ( $target_ix > $furthest_earleme ) {
                $parse->[Parse::Marpa::Internal::Recognizer::FURTHEST_EARLEME]
                    = $furthest_earleme = $target_ix;
            }
            STATE: for my $state (@{$states}) {
                my $reset =
                    $state->[Parse::Marpa::Internal::QDFA::RESET_ORIGIN];
                my $origin = $reset ? $target_ix : $parent;
		my $state_id = $state->[Parse::Marpa::Internal::QDFA::ID];
		my $name = sprintf 'S%d@%d-%d', $state_id, $origin, $target_ix;
                my $target_item = $earley_hash->{$name};
                unless ( defined $target_item ) {
                    $target_item = [];
                    @{$target_item}[
                        Parse::Marpa::Internal::Earley_item::NAME,
                        Parse::Marpa::Internal::Earley_item::STATE,
                        Parse::Marpa::Internal::Earley_item::PARENT,
                        Parse::Marpa::Internal::Earley_item::LINKS,
                        Parse::Marpa::Internal::Earley_item::TOKENS,
                        Parse::Marpa::Internal::Earley_item::SET
                        ]
                        = ( $name, $state, $origin, [], [], $target_ix );
                    $earley_hash->{$name} = $target_item;
                    push @{$target_set}, $target_item;
                }
                next STATE if $reset;
                push
                    @{  $target_item
                            ->[Parse::Marpa::Internal::Earley_item::TOKENS]
                        },
                    [ $earley_item, $value ]
                ;
            }    # for my $state

        }    # ALTERNATIVE

    }    # EARLEY_ITEM

    $parse->[CURRENT_SET]++;

    return 1;

}    # sub scan_set

sub complete_set {
    my $parse = shift;

    my ( $earley_set_list, $earley_hash, $grammar, $current_set,
        $furthest_earleme, $exhausted, $lexables_by_state )
        = @{$parse}[
        EARLEY_SETS,      EARLEY_HASH,   GRAMMAR, CURRENT_SET,
        FURTHEST_EARLEME, EXHAUSTED,     LEXABLES_BY_STATE,
        ];
    croak('Attempt to complete another earley set after parsing was exhausted')
        if $exhausted;

    my $earley_set  = $earley_set_list->[$current_set];

    $earley_set ||= [];

    my ( $QDFA, $symbols, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::QDFA,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my ( $trace_fh, $trace_completions );
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_completions =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS];
    }

    my $lexable_seen = [];
    $#{$lexable_seen} = $#{$symbols};

    # Important: more earley sets can be added in the loop
    my $earley_set_ix = -1;
    EARLEY_ITEM: while (1) {

        my $earley_item = $earley_set->[++$earley_set_ix];
        last EARLEY_ITEM unless defined $earley_item;

        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];
        my $state_id = $state->[Parse::Marpa::Internal::QDFA::ID];

        for my $lexable ( @{ $lexables_by_state->[$state_id] } ) {
            $lexable_seen->[$lexable] = 1;
        }

        next EARLEY_ITEM if $current_set == $parent;

        COMPLETE_RULE:
        for my $complete_symbol_name (
            @{ $state->[Parse::Marpa::Internal::QDFA::COMPLETE_LHS] } )
        {
            PARENT_ITEM:
            for my $parent_item ( @{ $earley_set_list->[$parent] } ) {
                my ( $parent_state, $grandparent ) = @{$parent_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT
                ];
                my $states =
                    $QDFA->[ $parent_state->[Parse::Marpa::Internal::QDFA::ID]
                    ]->[Parse::Marpa::Internal::QDFA::TRANSITION]
                    ->{$complete_symbol_name};
                next PARENT_ITEM unless defined $states;

                TRANSITION_STATE: for my $transition_state (@{$states}) {
                    my $reset =
                        $transition_state->[Parse::Marpa::Internal::QDFA::RESET_ORIGIN];
                    my $origin = $reset ? $current_set : $grandparent;
		    my $transition_state_id = $transition_state->[Parse::Marpa::Internal::QDFA::ID];
		    my $name = sprintf 'S%d@%d-%d', $transition_state_id, $origin, $current_set;
                    my $target_item = $earley_hash->{$name};
                    unless ( defined $target_item ) {
                        $target_item = [];
                        @{$target_item}[
                            Parse::Marpa::Internal::Earley_item::NAME,
                            Parse::Marpa::Internal::Earley_item::STATE,
                            Parse::Marpa::Internal::Earley_item::PARENT,
                            Parse::Marpa::Internal::Earley_item::LINKS,
                            Parse::Marpa::Internal::Earley_item::TOKENS,
                            Parse::Marpa::Internal::Earley_item::SET
                            ]
                            = ( $name, $transition_state, $origin, [], [], $current_set );
                        $earley_hash->{$name} = $target_item;
                        push @{$earley_set}, $target_item;
                    }    # unless defined $target_item
                    next TRANSITION_STATE if $reset;
                    push
                        @{  $target_item
                                ->[Parse::Marpa::Internal::Earley_item::LINKS]
                            },
                        [ $parent_item, $earley_item ]
                    ;
                }    # TRANSITION_STATE

            }    # PARENT_ITEM

        }    # COMPLETE_RULE

    }    # EARLEY_ITEM

    EARLEY_ITEM: for my $earley_item (@{$earley_set}) {
        my $links =
            $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS];
        my @sorted_links =
            map  { $_->[0] }
            ## no critic (BuiltinFunctions::ProhibitReverseSortBlock)
            sort { $b->[1] cmp $a->[1] }
            ## use critic
            map {
            [   $_,
                $_->[1]->[Parse::Marpa::Internal::Earley_item::STATE]
                    ->[Parse::Marpa::Internal::QDFA::PRIORITY]
            ]
            } @{$links};
        $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS] =
            \@sorted_links;
    }

    # TODO: Prove that the completion links are UNIQUE

    $parse->[Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET] =
        $current_set;
    $parse->[Parse::Marpa::Internal::Recognizer::LAST_COMPLETED_SET] =
        $current_set;

    if ($trace_completions) {
        print {$trace_fh} Parse::Marpa::show_earley_set($earley_set)
	  or croak('Cannot print to trace file');
    }

    # Dream up some efficiency hack here.  Memoize sorted lexables by state?
    my $lexables = [
        sort {
            $a->[Parse::Marpa::Internal::Symbol::PRIORITY]
                cmp $b->[Parse::Marpa::Internal::Symbol::PRIORITY]
            }
            map { $symbols->[$_] }
            grep { $lexable_seen->[$_] } ( 0 .. $#{$symbols} )
    ];
    return $lexables;

}    # sub complete_set

sub Parse::Marpa::Recognizer::find_complete_rule {
    my $parse         = shift;
    my $start_earleme = shift;
    my $symbol        = shift;
    my $last_earleme  = shift;

    my ( $default_parse_set, $earley_sets, ) = @{$parse}[
        Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
    ];

    # Set up the defaults for undefined arguments
    $start_earleme //= 0;
    $last_earleme  //= $default_parse_set;
    $last_earleme = $default_parse_set if $last_earleme > $default_parse_set;

    EARLEME:
    ## no critic (ProhibitCStyleForLoops)
    for (
        my $earleme = $last_earleme;
        $earleme >= $start_earleme;
        $earleme--
        )
    ## use critic
    {
        my $earley_set = $earley_sets->[$earleme];

        ITEM: for my $earley_item (@{$earley_set}) {
            my ( $state, $parent ) = @{$earley_item}[
                Parse::Marpa::Internal::Earley_item::STATE,
                Parse::Marpa::Internal::Earley_item::PARENT,
            ];
            next ITEM unless $parent == $start_earleme;
            if ( defined $symbol ) {
                my $complete_rules =
                    $state->[Parse::Marpa::Internal::QDFA::COMPLETE_RULES]
                    ->{$symbol};
                next ITEM unless $complete_rules;
            }
            my $complete_lhs =
                $state->[Parse::Marpa::Internal::QDFA::COMPLETE_LHS];
            next ITEM unless scalar @{$complete_lhs};
            return ( $earleme, $complete_lhs );
        }    # ITEM
    }    # EARLEME
    return;
}

1;

__END__

=pod

=head1 NAME

Parse::Marpa::Recognizer - Marpa Recognizer Objects

=head1 SYNOPSIS

=begin Parse::Marpa::test_document:

## next 2 displays
in_equation_s_t($_)

=end Parse::Marpa::test_document:

    my $recce = new Parse::Marpa::Recognizer( { grammar => $grammar } );

    my $fail_offset = $recce->text( '2-0*3+1' );
    if ( $fail_offset >= 0 ) {
        croak("Parse failed at offset $fail_offset");
    }

Z<>

=begin Parse::Marpa::test_document:

## next 5 displays
in_equation_t($_)

=end Parse::Marpa::test_document:

    my $recce = new Parse::Marpa::Recognizer({grammar => $grammar});

    my $op = $grammar->get_symbol('Op');
    my $number = $grammar->get_symbol('Number');

    my @tokens = (
	[$number, 2, 1],
	[$op, q{-}, 1],
	[$number, 0, 1],
	[$op, q{*}, 1],
	[$number, 3, 1],
	[$op, q{+}, 1],
	[$number, 1, 1],
    );

    TOKEN: for my $token (@tokens) {
	next TOKEN if $recce->earleme($token);
	croak('Parsing exhausted at character: ', $token->[1]);
    }

    $recce->end_input();

=head1 DESCRIPTION

Marpa parsing takes place in three major phases: grammar creation, input recognition
and parse evaluation.
Once a grammar object has rules,
a recognizer object can be created from it.
The recognizer accepts input and
can be used to create a Marpa evaluator object.

=head2 Tokens and Earlemes

Marpa allows ambiguous tokens.
Several Marpa tokens can start at a single parsing location.
Marpa tokens can be of various lengths.
Marpa tokens can even overlap.

For most parsers, position is location in a token stream.
To deal with variable-length and overlapping tokens,
Marpa needs a more flexible idea of location.
This flexibility is provided by tracking parse position in B<earlemes>.
Earlemes are named after Jay Earley, the inventor of the first algorithm
in Marpa's lineage.

If you do your lexing with the C<text> method,
you will use a
one-character-per-earleme model.
The raw input to the parse will be a string
made up from the series of strings and string references
provided as arguments in calls to C<text>.
Every character will be treated as being exactly one
earleme in length.

Marpa is not restricted to the one-character-per-earleme model.
With the C<earleme> method, you can structure your input in almost any way you like.
You can, for example, create a token stream and use a one-token-per-earleme model,
and this would be equivalent to the way things are typically done in other parsers.
Marpa also allows you to structure your input in special ways to suit particular applications.

There are three restrictions on mapping tokens to earlemes:

=over 4

=item 1

Scanning always starts at earleme 0.

=item 2

Tokens must be scanned in earleme order.
That is, all the tokens starting at earleme C<N>
must be scanned before any token starting at earleme C<N+1>.

=item 3

Tokens cannot be zero or negative in earleme length.

=back

B<Earleme number N>, or B<earleme N> means the location B<N> earlemes
after earleme 0.
B<Length> in earlemes means what you expect it does.
The length from earleme 3 to earleme 6,
for instance, is 3 earlemes.

When a token is scanned, the start of the token is put at the B<current earleme>.
The end of the token is at earleme number B<c+l>,
where B<c> is the location number of the current earleme,
and B<l> is the length of the token.
The length of the token must be greater than zero.

The B<default end of parsing> is tracked by each recognizer.
The default end of parsing is at earleme 0 when the recognizer is created.
It is incremented on calls to the C<text> and C<earleme> methods,
as described below in the sections for those methods.
When an evaluator object is created from a recognizer object,
it inherits the recognizer object's
default end of parsing.

=head2 Exhaustion

At the start of parsing,
the B<furthest earleme> is earleme 0.
When a token is recognized, its end earleme is determined by
adding the token length to the current earleme.
If the new token's end earleme is after the B<furthest earleme>,
the B<furthest earleme> is set at the new token's end earleme.

No more successful parses are possible when
Marpa reaches an empty Earley set which is
either immediately before the furthest earleme,
or which is anywhere after the furthest earleme.
At this point, the recognizer is said to
be B<exhausted>.
A B<recognizer> is B<active>,
if and only if it is not exhausted.

When the recognizer is exhausted or active,
I sometimes say, more loosely, that the parser is exhausted (active),
or that parsing is exhausted (active).
In context of a particular parse being worked on,
we can also speak of a parse being exhausted or active.
Remember, however, that an exhausted recognizer
can contain successful parses prior to the current earleme.
In fact, successful parsing always leaves the recognizer exhausted.

Because tokens can be more than one earleme in length,
parses in Marpa can remain active even if
no token is found at the current earleme.
In the one-character-per-earleme model,
stretches where no token either begins or ends
can be many earlemes in length.

=head2 Cloning

The C<new> constructor requires a grammar to be specified in
one of its arguments.
By default, the C<new> constructor clones the grammar object.
This is done so that recongnizers do not interfere with each other by
modifying the same data.
Cloning is the default behavior, and is always safe.

While safe, cloning does impose an overhead in memory and time.
This can be avoided by using the C<clone> option with the C<new>
constructor.
Not cloning is safe if you know that the grammar object will not be shared by another recognizer
or by more than one evaluator.

It is very common for a Marpa program to have a simple
structure, where no more than one recognizer is created from any grammar,
and no more than one evaluator is created from any recognizer.
When this is the case, cloning is unnecessary.

=head1 METHODS

=head2 new

=begin Parse::Marpa::test_document:

## next display
in_misc_pl($_)

=end Parse::Marpa::test_document:

    my $recce = new Parse::Marpa::Recognizer({
       grammar=> $grammar,
       lex_preamble => $new_lex_preamble,
    });

The C<new> method's one, required, argument is a hash reference of named
arguments.
The C<new> method either returns a new parse object or throws an exception.
Either the C<stringified_grammar> or the C<grammar> named argument must be specified, but not both.
A recognizer is created with
the current earleme and
the default end of parsing
both set at earleme 0.

If the C<grammar> option is specified, 
its value must be a grammar object with rules defined.
By default, the grammar is cloned for use in the recognizer.

If the C<stringified_grammar> option is specified, 
its value must be a Perl 5 string containing a stringified Marpa grammar,
as produced by L<C<Parse::Marpa::Grammar::stringify>|Parse::Marpa::Grammar/"stringify">.
It will be unstringified for use in the recognizer.
When the C<stringified_grammar> option is specified, 
the resulting grammar is never cloned,
regardless of the setting of the C<clone> argument.

If the C<clone> argument is set to 1,
and the grammar argument is not in stringified form,
C<new> clones the grammar object.
This prevents that multiple
evaluators from interfering with each other's data.
This is the default and is always safe.
If C<clone> is set to 0,
the evaluator will work directly with
the grammar object which was its argument.
See L<above|/"Cloning"> for more detail.

Marpa options can also
be named arguments to C<new>.
For these, see L<Parse::Marpa::Doc::Options>.

=head2 text

=begin Parse::Marpa::test_document:

## next display
in_equation_s_t($_)

=end Parse::Marpa::test_document:

    my $fail_offset = $recce->text( '2-0*3+1' );
    if ( $fail_offset >= 0 ) {
        croak("Parse failed at offset $fail_offset");
    }

Extends the parse using the one-character-per-earleme model.
The one, required, argument must be
a string or a
reference to a string which contains text to be parsed.
If the parse is active after the text has been processed,
the default end of parsing is set to the end of the text,
the current earleme is set to the earleme just after the end of text,
and -1 is returned.

If the recognizer is exhausted by the input,
the character offset at which parsing was exhausted is returned.
The character offset is the offset within the string which is the current argument.
This offset is not necessarily the offset within the entire raw input.
A zero return means that parsing was exhausted at character offset zero.
The default end of parsing remains at the last earleme at which the parse was
active.
Failures, other than exhausted recognizers, are thrown as exceptions.

When you use the C<text> method for input,
all characters will be treated as one earleme in length.
The first character of the first string argument
will be at character offset 0,
and will start at earleme 0 and end at earleme 1.
For each subsequent character of the first string argument,
the character offset will increase by one.
In the first string argument,
the character at character offset I<c>
will always be one earleme long and end at earleme I<c+1>.

Within each call to C<text>,
every character increases
the character offset, start earleme and end earleme by one.
Each call to C<text> resets the character offset number to 0,
but does not reset the earleme numbering.

Terminals are recognized in the text
using the lexers that were specified in the porcelain
or the plumbing.
The earleme length of each token is
set to the length of the token in characters.
(If a token has a "lex prefix",
the length of the lex prefix counts as part of the token length.)

Terminals cannot span calls to C<text>.
If a series of characters which otherwise would be recognized as a terminal
by a lexer is split between two calls to C<text>,
that terminal will not be recognized.

=head2 earleme

=begin Parse::Marpa::test_document:

## next display
in_ah2_t($_)

=end Parse::Marpa::test_document:

    my $a = $grammar->get_symbol('a');
    $recce->earleme([$a, 'a', 1]) or croak('Parsing exhausted');

The C<earleme> method adds zero or more tokens,
then moves the current earleme forward by one earleme.
Unlike C<text>, the C<earleme> method assumes no particular model of the input.

The C<earleme> method takes zero or more arguments.
Each argument represents a token which starts at the B<current earleme>.
More than one token may start at each earleme,
because ambiguous lexing is allowed.
There might be no tokens which start at the current earleme,
in which case C<earleme> can be called with no arguments.

Each token argument is a reference to a three element array.
The first element is a "cookie" for the token's symbol,
as returned by the C<Parse::Marpa::Grammar::get_symbol> method
or the C<get_symbol> method of a porcelain interface.
The second element is the token's value in the parse,
and may be any value legal in Perl 5, including undefined.
The third is the token's length in earlemes.

The C<earleme> method first
adds the tokens in the arguments.
If, after all tokens have been added,
the parse is still B<active>,
the default end of parsing is set to the current earleme.
The current earleme is then advanced by one
and the C<earleme> method returns 1.

It is possible that for a call to B<earleme>
with no token arguments
to exhaust the recognizer.
When this happens,
the B<earleme> method returns 0.
The default end of parsing remains
at the last earleme at which the parse was active.
The C<earleme> method throws an exception on other failures.

An earleme remains the current earleme during only one call of the C<earleme> method.
All tokens starting at that earleme must be added in that call.
The first time that the C<earleme> method is called in a recognizer,
the current earleme is at earleme 0.

This is the low-level token input method, and allows maximum
control over scanning.
No model of the input,
or of the relationship between the tokens and the earlemes,
is assumed.  The user is free to invent her own.

=head2 end_input

=begin Parse::Marpa::test_document:

## next display
in_equation_t($_)

=end Parse::Marpa::test_document:

    $recce->end_input();

Used to indicate the end of input.
C<end_input> takes no arguments.
C<end_input> processes the input
out to the furthest earleme;
sets the default end of parsing to the furthest earleme;
and advances
the current earleme to one earleme past the furthest earleme.
If it does not throw an exception,
C<end_input> returns a true value.

Since positioning the current earleme past the furthest
earleme leaves the recognizer exhausted,
any further calls to C<text> or C<earleme> will throw an
exception.
C<end_input> itself is idempotent.
If called more than once, on subsequent calls,
C<end_input> will do nothing, successfully.

=head2 stringify

=begin Parse::Marpa::test_document:

## next display
in_misc_pl($_)

=end Parse::Marpa::test_document:

    my $stringified_recce = $recce->stringify();

The C<stringify> method takes as its single argument a recognizer object
and converts it into a string.
It returns a reference to the string.
The string is created 
using L<Data::Dumper>.
On failure, C<stringify> throws an exception.

=head2 unstringify

=begin Parse::Marpa::test_document:

## next 2 displays
in_misc_pl($_)

=end Parse::Marpa::test_document:

    $recce = Parse::Marpa::Recognizer::unstringify($stringified_recce, $trace_fh);

    $recce = Parse::Marpa::Recognizer::unstringify($stringified_recce);

The C<unstringify> static method takes a reference to a stringified recognizer as its first
argument.
Its second, optional, argument is a file handle.
The file handle argument will be used both as the unstringified recognizer's trace file handle,
and for any trace messages produced by C<unstringify> itself.
C<unstringify> returns the unstringified recognizer object unless it throws an
exception.

If the trace file handle argument is omitted,
it defaults to C<STDERR>
and the unstringified recognizer's trace file handle reverts to the default for a new
recognizer, which is also C<STDERR>.
The trace file handle argument is necessary because in the course of stringifying,
the recognizer's original trace file handle may have been lost.

=head2 clone

=begin Parse::Marpa::test_document:

## next 2 displays
in_misc_pl($_)

=end Parse::Marpa::test_document:

    my $cloned_recce = $recce->clone();

The <clone> method creates a useable copy of a recognizer object.
It returns a successfully cloned recognizer object,
or throws an exception.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 LICENSE AND COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5.10.0.

=cut
