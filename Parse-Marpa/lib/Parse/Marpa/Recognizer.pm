use 5.010_000;

use warnings;
no warnings "recursion";
use strict;
use integer;

package Parse::Marpa::Read_Only;

our $rule;

package Parse::Marpa::Internal::Earley_item;

# Elements of the EARLEY ITEM structure
# Note that these are Earley items as modified by Aycock & Horspool, with SDFA states instead of
# LR(0) items.
#
use constant STATE => 0;    # the SDFA state
use constant PARENT =>
    1;    # the number of the Earley set with the parent item(s)
use constant TOKENS => 2;    # a list of the links from token scanning
use constant LINKS  => 3;    # a list of the links from the completer step
use constant SET    => 4;    # the set this item is in, for debugging
     # these next elements are "notations" for iterating over the parses
use constant POINTER      => 5;     # symbol just before pointer
use constant RULES        => 6;     # current list of rules
use constant RULE_CHOICE  => 7;     # current choice of rule
use constant LINK_CHOICE  => 8;     # current choice of link
use constant TOKEN_CHOICE => 9;     # current choice of token
use constant VALUE        => 10;    # value of pointer symbol
use constant PREDECESSOR  => 11;    # the predecessor link, if we have a value
use constant SUCCESSOR    => 12;    # the predecessor link, in reverse
use constant EFFECT       => 13;    # the cause link, in reverse
                                    # or the "parent" item
use constant LHS          => 14;    # LHS symbol

# Note that (at least right now) items either have a SUCCESSOR
# or an EFFECT, never both.

package Parse::Marpa::Internal::Recognizer;

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

my $parse_number = 0;

# Elements of the RECOGNIZER structure
use constant GRAMMAR       => 0;    # the grammar used
use constant CURRENT_SET   => 1;    # index of the first incomplete Earley set
use constant EARLEY_SETS   => 2;    # the array of the Earley sets
use constant EARLEY_HASHES => 3;    # the array of hashes used
                                    # to build the Earley sets
use constant CURRENT_PARSE_SET => 4;   # the set being taken as the end of
                                       # parse for an evaluation
                                       # only undef if there are no evaluation
                                       # notations in the earley items
use constant START_ITEM => 5;    # the start item for the current evaluation
use constant FURTHEST_EARLEME         => 7;    # last earley set with a token
use constant EXHAUSTED                => 8;    # parse can't continue?
use constant DEFAULT_PARSE_SET        => 14;
use constant EVALUATOR                => 15;  # the current evaluator for this recognizer
use constant PACKAGE       => 17;              # special "safe" namespace
use constant LEXERS            => 22;    # an array, indexed by symbol id,
                                         # of the lexer for each symbol
use constant LEXABLES_BY_STATE => 23;    # an array, indexed by SDFA state id,
                                         # of the lexables belonging in it
use constant PRIORITIES        => 24;    # an array, indexed by SDFA state id,
                                         # of its priority
use constant LAST_COMPLETED_SET => 26;   # last earley set completed

# Given symbol, returns null value, calculating it
# if necessary.
#
# Assumes all but CHAF values have already been set
sub set_null_symbol_value {
    my $symbol = shift;

    # if it's not a CHAF nulling symbol,
    # or the value is already set, use what we have
    my $chaf_nulling = $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
    my $null_value = $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE];
    if (not $chaf_nulling or defined $null_value) {
        return $null_value;
    }

    $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
        = [ (map { set_null_symbol_value($_) } @$chaf_nulling), [] ];

} # null symbol value

sub set_null_values {
    my $grammar        = shift;
    my $package        = shift;

    my (
        $rules, $symbols, $tracing, $default_null_value
    )  = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_actions = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ACTIONS ];
    }

    SYMBOL: for my $symbol (@$symbols) {
        next SYMBOL if $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
            = $default_null_value;
    }

    # Before tackling the CHAF symbols, set null values specified in
    # empty rules.
    RULE: for my $rule (@$rules) {

        my $action = $rule->[Parse::Marpa::Internal::Rule::ACTION];

        # Set the null value of symbols from the action for their
        # empty rules
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];

        # Empty rule with action?
        if (defined $action and @$rhs <= 0) {
            my $lhs = $rule->[Parse::Marpa::Internal::Rule::LHS];
            my $nulling_alias = $lhs->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
            next RULE unless defined $nulling_alias;

            my $code = "package $package;\nlocal(" . '$_' . ")=[]; $action"; 
            my @warnings;
            local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
            my $null_value = eval($code);
            my $fatal_error = $@;
            if ($fatal_error or @warnings) {
                Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                    "evaluating null value",
                    "evaluating null value for "
                        . $nulling_alias->[Parse::Marpa::Internal::Symbol::NAME],
                    \$action
                );
            }
            $nulling_alias->[Parse::Marpa::Internal::Symbol::NULL_VALUE] = $null_value;

            if ($trace_actions) {
                print $trace_fh "Setting null value for symbol ",
                    $nulling_alias->[Parse::Marpa::Internal::Symbol::NAME],
                    " from\n", $code, "\n",
                    " to ",
                    Parse::Marpa::show_value(\$null_value),
                    "\n";
            }

        }

    } # RULE

    SYMBOL: for my $symbol (@$symbols) {
        next SYMBOL unless $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
            = set_null_symbol_value($symbol);
    }

    if ($trace_actions) {
        SYMBOL: for my $symbol (@$symbols) {
            next SYMBOL unless $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];

            print $trace_fh "Setting null value for CHAF symbol ",
                $symbol->[Parse::Marpa::Internal::Symbol::NAME],
                " to ",
                Dumper( $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]),
                ;
        }
    }

} # set_null_values

# Set rule actions
sub set_actions {
    my $grammar        = shift;
    my $package        = shift;

    my (
        $rules, $symbols, $symbol_hash, $SDFA, $tracing,
        $default_prefix,
        $default_suffix,
        $default_action,
    ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SDFA,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_ACTION,
    ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_actions = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ACTIONS ];
    }

    RULE: for my $rule (@$rules) {

        next RULE unless $rule->[Parse::Marpa::Internal::Rule::USEFUL];

        my $action = $rule->[Parse::Marpa::Internal::Rule::ACTION];

        ACTION: {

            $action //= $default_action;
            last ACTION unless defined $action;

            # HAS_CHAF_RHS and HAS_CHAF_LHS would work well as a bit
            # mask in a C implementation
            my $has_chaf_lhs =
                $rule->[Parse::Marpa::Internal::Rule::HAS_CHAF_LHS];
            my $has_chaf_rhs =
                $rule->[Parse::Marpa::Internal::Rule::HAS_CHAF_RHS];

            last ACTION unless $has_chaf_lhs or $has_chaf_rhs;

            if ( $has_chaf_rhs and $has_chaf_lhs ) {
                $action = q{ $_; };
                last ACTION;
            }

            # At this point has chaf rhs or lhs but not both
            if ($has_chaf_lhs) {

                $action = q{
                        push(@$_, []);
                        $_;
                    };
                last ACTION;

            }

            # at this point must have chaf rhs and not a chaf lhs

            my $original_rule = $Parse::Marpa::Read_Only::rule
                ->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE];

            $action = q{
                TAIL: for (;;) {
                    my $tail = pop @$_;
                    last TAIL unless scalar @$tail;
                    push(@$_, @$tail);
                }
            }    # q string
                . $action;

        }    # ACTION

        next RULE unless defined $action;

        my $code =
            "sub {\n" . "    package " . $package . ";\n" . $action . "\n}";

        if ($trace_actions) {
            print $trace_fh "Setting action for rule ",
                Parse::Marpa::brief_rule($rule), " to\n", $code, "\n";
        }

        my $closure;
        {
            my @warnings;
            local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
            $closure = eval $code;
            my $fatal_error = $@;
            if ($fatal_error or @warnings) {
                Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                    "compiling action",
                    "compiling action for "
                        . Parse::Marpa::brief_original_rule($rule),,
                    \$code
                );
            }
        }

        $rule->[Parse::Marpa::Internal::Rule::ACTION] = $code;
        $rule->[Parse::Marpa::Internal::Rule::CLOSURE] = $closure;

    }    # RULE

    my @lexers;
    $#lexers = $#$symbols;

    SYMBOL: for ( my $ix = 0; $ix <= $#lexers; $ix++ ) {

        my $symbol = $symbols->[$ix];
        my ( $name, $regex, $action, $symbol_prefix, $symbol_suffix ) = @{$symbol}[
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
        $prefix = qr/$prefix/ if defined $prefix;
        my $suffix = $symbol_suffix // $default_suffix;
        $suffix = qr/$suffix/ if defined $suffix;

        given ($action) {
            when (undef) {;}    # do nothing
                                # Right now do nothing but find lex_q_quote
            when ("lex_q_quote") {
                $lexers[$ix] = [\&Parse::Marpa::Lex::lex_q_quote, $prefix, $suffix];
            }
            when ("lex_regex") {
                $lexers[$ix] = [\&Parse::Marpa::Lex::lex_regex, $prefix, $suffix];
            }
            default {
                my $code = q'
                        sub {
                            my $STRING = shift;
                            my $START = shift;
                     '
                    . "package " . $package . ";\n" . $action . "; return\n}";

                if ($trace_actions) {
                    print $trace_fh
                        "Setting action for terminal ", $name, " to\n", $code,
                        "\n";
                }

                my $closure;
                {
                    my @warnings;
                    local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
                    $closure = eval $code;
                    my $fatal_error = $@;
                    if ($fatal_error or @warnings) {
                        Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                            "compiling action",
                            "compiling action for $name",
                            \$code
                        );
                    }
                }

                $symbol->[ Parse::Marpa::Internal::Symbol::ACTION ] = $code;
                $lexers[$ix] = [$closure, $prefix, $suffix];

            }
        }

    }    # SYMBOL

    my @lexables_by_state;
    $#lexables_by_state = $#$SDFA;

    for my $state (@$SDFA) {
        my ( $id, $transition ) = @{$state}[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::TRANSITION,
        ];
        $lexables_by_state[$id] = [
            grep { $lexers[$_] }
                map {
                $symbol_hash->{$_}->[Parse::Marpa::Internal::Symbol::ID]
                }
                grep { $_ ne "" }
                keys %$transition
        ];
    }

    return ( \@lexers, \@lexables_by_state, );

}    # sub set_actions

sub compile_regexes {
    my $grammar = shift;
    my ( $symbols, $default_lex_prefix, $default_lex_suffix, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
    ];

    SYMBOL: for my $symbol (@$symbols) {
        my $regex = $symbol->[Parse::Marpa::Internal::Symbol::REGEX];
        next SYMBOL unless defined $regex;
        if ( "" =~ $regex ) {
            my $name = $symbol->[Parse::Marpa::Internal::Symbol::NAME];
            croak( "Attempt to add nullable terminal: ", $name );
        }
        my $prefix = $symbol->[Parse::Marpa::Internal::Symbol::PREFIX]
            // $default_lex_prefix;
        my $suffix = $symbol->[Parse::Marpa::Internal::Symbol::SUFFIX]
            // $default_lex_suffix;
        my $compiled_regex = qr/
            \G
            (?<mArPa_prefix>$prefix)
            (?<mArPa_match>$regex)
            (?<mArPa_suffix>$suffix)
        /xms;
        $symbol->[Parse::Marpa::Internal::Symbol::REGEX] = $compiled_regex;
    }    # SYMBOL

}

sub set_priorities {
    my $grammar    = shift;
    my $priorities = [];
    my $problem    = 0;

    my ($trace_fh, $trace_priorities);
    if ($grammar->[ Parse::Marpa::Internal::Grammar::TRACING ]) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_priorities = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES ];
    }
    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    $#$priorities = $#$SDFA;

    for my $state (@$SDFA) {
        my $priority;
        my $priority_conflict = 0;
        my ( $id, $complete_rules_by_lhs ) = @{$state}[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::COMPLETE_RULES,
        ];
        my @complete_rules;
        LHS: for my $lhs_id ( 0 .. $#$complete_rules_by_lhs ) {
            my $rules = $complete_rules_by_lhs->[$lhs_id];
            next LHS unless defined $rules;
            push( @complete_rules, @$rules );
        }
        COMPLETE_RULE: for my $complete_rule (@complete_rules) {
            my $rule_priority =
                $complete_rule->[Parse::Marpa::Internal::Rule::PRIORITY];
            given ($priority) {
                when (undef) { $priority = $rule_priority }
                when ( $rule_priority != $_ ) { $priority_conflict++; }
            }
        }
        if ($priority_conflict) {
            $problem++;
            carp( "Priority conflict in SDFA ", $id );
            COMPLETE_RULE: for my $complete_rule (@complete_rules) {
                my $rule_priority =
                    $complete_rule->[Parse::Marpa::Internal::Rule::PRIORITY];
                carp(
                    "SDFA ", $id, ": ",
                    Parse::Marpa::brief_rule($complete_rule),
                    "has priority ",
                    $rule_priority
                );
            }
        }
        $priorities->[$id] = $priority // 0;
        if ($trace_priorities) {
            say $trace_fh "Priority for state $id: ", $priorities->[$id];
        }
    }    # for each SDFA state
    if ($problem) {
        croak( "Marpa cannot continue: ", $problem, " priority conflicts" );
    }

    $priorities;

}    # sub set_priorities

sub eval_grammar {
    my $parse          = shift;
    my $grammar        = shift;

    local ($Data::Dumper::Terse)       = 1;
    my $package = $parse->[Parse::Marpa::Internal::Recognizer::PACKAGE] =
        sprintf( "Parse::Marpa::P_%x", $parse_number++ );

    my $preamble = $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE];
    my $default_action = $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION];
    my $default_null_value = $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE];

    if ( defined $preamble ) {
        my @warnings;
        local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
        eval( "package " . $package . ";\n" . $preamble );
        my $fatal_error = $@;
        if ($fatal_error or @warnings) {
            Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                "evaluating preamble",
                "evaluating preamble",
                \$preamble
            );
        }
    }

    compile_regexes($grammar);
    set_null_values( $grammar, $package );
    @{$parse}[ LEXERS, LEXABLES_BY_STATE ] =
        set_actions( $grammar, $package );
    $parse->[PRIORITIES] = set_priorities($grammar);
    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::EVALED;

}

# Returns the new parse object or throws an exception
sub Parse::Marpa::Recognizer::new {
    my $class = shift;

    my $parse = [];
    my $ambiguous_lex;
    my $preamble;
    # do we have a private copy of the grammar?
    my $private_grammar = 0;

    my ($args) = @_;
    my $arg_trace_fh = $args->{trace_file_handle};

    my $grammar = $args->{grammar};
    if (not defined $grammar) {
	my $compiled_grammar = $args->{compiled_grammar};
	croak("No grammar specified") unless defined $compiled_grammar;
	delete $args->{compiled_grammar};
	my $trace_fh = $arg_trace_fh // (*STDERR);
	$grammar = Parse::Marpa::Grammar::decompile($compiled_grammar, $trace_fh);
	$private_grammar = 1;
    } else {
	delete $args->{grammar};
    }

    my $grammar_class = ref $grammar;
    croak(
        "${class}::new() grammar arg has wrong class: $grammar_class")
        unless $grammar_class eq "Parse::Marpa::Grammar";

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING ];

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::Grammar::show_problems($grammar),
            "Attempt to parse grammar with fatal problems\n",
            "Marpa cannot proceed",
        );
    }

    if ( $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] ) {
        croak(
            "Attempt to parse grammar marked academic\n",
            "Marpa cannot proceed"
        );
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if ($phase < Parse::Marpa::Internal::Phase::RULES
         or $phase >= Parse::Marpa::Internal::Phase::EVALED)
    {
	croak(
	    "Attempt to parse grammar in inappropriate phase ",
	    Parse::Marpa::Internal::Phase::description($phase)
	);
    }

    if ($phase < Parse::Marpa::Internal::Phase::PRECOMPUTED
	    or not $private_grammar) {
	my $compiled_grammar = Parse::Marpa::Grammar::compile($grammar);
	my $trace_fh
	    = $arg_trace_fh
	    // $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
	$grammar = Parse::Marpa::Grammar::decompile($compiled_grammar, $trace_fh);
    }


    # options are not set until *AFTER* the grammar is deep copied
    Parse::Marpa::Grammar::set($grammar, $args);

    # Finalize the value of opaque
    # undef means opaque (boolean true, or 1)
    $grammar->[ Parse::Marpa::Internal::Grammar::OPAQUE ] //= 1;

    eval_grammar( $parse, $grammar );

    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::IN_USE;

    my $earley_hash;
    my $earley_set;
    my $item;

    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];

    # Here I rely on an assumption about the numbering
    # of the SDFA states -- specifically, that state 0 contains the
    # start productions.
    my $SDFA0 = $SDFA->[0];
    my $key = pack( "JJ", $SDFA0 + 0, 0 );
    @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::PARENT,
        Parse::Marpa::Internal::Earley_item::TOKENS,
        Parse::Marpa::Internal::Earley_item::LINKS,
        Parse::Marpa::Internal::Earley_item::SET
        ]
        = ( $SDFA0, 0, [], [], 0 );
    push( @$earley_set, $item );
    $earley_hash->{$key} = $item;

    my $resetting_state =
        $SDFA0->[Parse::Marpa::Internal::SDFA::TRANSITION]->{""};
    if ( defined $resetting_state ) {
        $key = pack( "JJ", $resetting_state, 0 );
        undef $item;
        @{$item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT,
            Parse::Marpa::Internal::Earley_item::TOKENS,
            Parse::Marpa::Internal::Earley_item::LINKS,
            Parse::Marpa::Internal::Earley_item::SET
            ]
            = ( $resetting_state, 0, [], [], 0 );
        push( @$earley_set, $item );
        $earley_hash->{$key} = $item;
    }

    @{$parse}[
        DEFAULT_PARSE_SET, CURRENT_SET,       FURTHEST_EARLEME,
        EARLEY_HASHES,     GRAMMAR,           EARLEY_SETS,
        LAST_COMPLETED_SET,
        ]
        = (
        0, 0, 0, [$earley_hash],
        $grammar, [$earley_set],
        -1,
        );

    bless $parse, $class;
}

# Viewing methods, for debugging

sub Parse::Marpa::brief_earley_item {
    my $item = shift;
    my $ii   = shift;
    my ( $state, $parent, $set ) = @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::PARENT,
        Parse::Marpa::Internal::Earley_item::SET
    ];
    my ( $id, $tag ) = @{$state}[
        Parse::Marpa::Internal::SDFA::ID,
        Parse::Marpa::Internal::SDFA::TAG
    ];
    my $text = ( $ii and defined $tag ) ? ( "St" . $tag ) : ( "S" . $id );
    $text .= '@' . $parent . '-' . $set;
}

sub show_token_choice {
    my $token = shift;
    my $ii    = shift;
    "[p="
        . Parse::Marpa::brief_earley_item( $token->[0], $ii ) . "; t="
        . $token->[1] . "]";
}

sub show_link_choice {
    my $link = shift;
    my $ii   = shift;
    "[p="
        . Parse::Marpa::brief_earley_item( $link->[0], $ii ) . "; c="
        . Parse::Marpa::brief_earley_item( $link->[1], $ii ) . "]";
}

sub Parse::Marpa::show_earley_item {
    my $item = shift;
    my $ii   = shift;
    my ($tokens,      $links,        $rules,     $rule_choice,
        $link_choice, $token_choice, $value,     $pointer,
        $lhs,         $predecessor,  $successor, $effect,
        )
        = @{$item}[
        Parse::Marpa::Internal::Earley_item::TOKENS,
        Parse::Marpa::Internal::Earley_item::LINKS,
        Parse::Marpa::Internal::Earley_item::RULES,
        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
        Parse::Marpa::Internal::Earley_item::VALUE,
        Parse::Marpa::Internal::Earley_item::POINTER,
        Parse::Marpa::Internal::Earley_item::LHS,
        Parse::Marpa::Internal::Earley_item::PREDECESSOR,
        Parse::Marpa::Internal::Earley_item::SUCCESSOR,
        Parse::Marpa::Internal::Earley_item::EFFECT,
        ];

    my $text = Parse::Marpa::brief_earley_item( $item, $ii );
    $text .= "  predecessor: " . Parse::Marpa::brief_earley_item($predecessor)
        if defined $predecessor;
    $text .= "  successor: " . Parse::Marpa::brief_earley_item($successor)
        if defined $successor;
    $text .= "  effect: " . Parse::Marpa::brief_earley_item($effect)
        if defined $effect;
    my @symbols;
    push( @symbols,
        "pointer: " . $pointer->[Parse::Marpa::Internal::Symbol::NAME] )
        if defined $pointer;
    push( @symbols, "lhs: " . $lhs->[Parse::Marpa::Internal::Symbol::NAME] )
        if defined $lhs;
    $text .= "\n  " . join( "; ", @symbols ) if @symbols;
    $text .= "\n  value: " . Parse::Marpa::show_value( $value, $ii )
        if defined $value;

    if ( defined $tokens and @$tokens ) {
        $text .= "\n  token choice " . $token_choice;
        for my $token (@$tokens) {
            $text .= " " . show_token_choice( $token, $ii );
        }
    }
    if ( defined $links and @$links ) {
        $text .= "\n  link choice " . $link_choice;
        for my $link (@$links) {
            $text .= " " . show_link_choice( $link, $ii );
        }
    }
    if ( defined $rules and @$rules ) {
        $text .= "\n  rule choice " . $rule_choice;
        for my $rule (@$rules) {
            $text .= " [ " . Parse::Marpa::brief_rule($rule) . " ]";
        }
    }
    $text;
}

sub Parse::Marpa::show_earley_set {
    my $earley_set = shift;
    my $ii         = shift;
    my $text       = "";
    for my $earley_item (@$earley_set) {
        $text .= Parse::Marpa::show_earley_item( $earley_item, $ii ) . "\n";
    }
    $text;
}

sub Parse::Marpa::show_earley_set_list {
    my $earley_set_list  = shift;
    my $ii               = shift;
    my $text             = "";
    my $earley_set_count = @$earley_set_list;
    LIST: for ( my $ix = 0; $ix < $earley_set_count; $ix++ ) {
        my $set = $earley_set_list->[$ix];
        next LIST unless defined $set;
        $text .= "Earley Set $ix\n"
            . Parse::Marpa::show_earley_set( $set, $ii );
    }
    $text;
}

sub Parse::Marpa::Recognizer::show_status {
    my $parse = shift;
    my $ii    = shift;
    my ( $current_set, $furthest_earleme, $earley_set_list ) =
        @{$parse}[ CURRENT_SET, FURTHEST_EARLEME, EARLEY_SETS ];
    my $text =
          "Current Earley Set: "
        . $current_set
        . "; Furthest: "
        . $furthest_earleme . "\n";
    $text .= Parse::Marpa::show_earley_set_list( $earley_set_list, $ii );
}

# check class of parse?
sub Parse::Marpa::Recognizer::earleme {
    my $parse = shift;

    my $grammar = $parse->[ Parse::Marpa::Internal::Recognizer::GRAMMAR ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    # lexables not checked -- don't use prediction here
    # maybe add this as an option?
    my $lexables = Parse::Marpa::Internal::Recognizer::complete_set($parse);
    return Parse::Marpa::Internal::Recognizer::scan_set( $parse, @_ );
}

# Returns the position where the parse was exhausted,
# or -1 if the parse is not exhausted

# First arg is the current parse object
# Second arg is ref to string
sub Parse::Marpa::Recognizer::text {
    my $parse     = shift;
    my $input_ref = shift;
    my $length    = shift;
    croak("Parse::Marpa::Recognizer::text() third argument not yet implemented")
        if defined $length;

    croak("text argument to Parse::Marpa::Recognizer::text() must be string ref")
        unless ref $input_ref eq "SCALAR";

    my ( $grammar, $earley_sets, $current_set, 
        $lexers, )
        = @{$parse}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
        Parse::Marpa::Internal::Recognizer::CURRENT_SET,
        Parse::Marpa::Internal::Recognizer::LEXERS,
        ];

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_lex_tries;
    my $trace_lex_matches;
    if ($tracing) {
         $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
         $trace_lex_tries = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ];
         $trace_lex_matches = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ];
    }

    my (
        $symbols, $ambiguous_lex
    ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX,
    ];

    $length = length $$input_ref unless defined $length;

    POS: for ( my $pos = ( pos $$input_ref // 0 ); $pos < $length; $pos++ ) {
        my @alternatives;

        # NOTE: Often the number of the earley set, and the idea of
        # lexical position will correspond.  Be careful that Marpa
        # imposes no such requirement, however.

        my $lexables = complete_set($parse);

        if ( $trace_lex_tries and scalar @$lexables ) {
            my $string_to_match = substr( $$input_ref, $pos, 20 );
            $string_to_match
                =~ s/([\x00-\x1F\x7F-\xFF])/sprintf("{%#.2x}", ord($1))/ge;
            say $trace_fh "Match target at $pos: ",
                $string_to_match;
        }

        LEXABLE: for my $lexable (@$lexables) {
            my ($symbol_id) = @{$lexable}[Parse::Marpa::Internal::Symbol::ID];
            if ($trace_lex_tries) {
                print $trace_fh "Trying to match ",
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos\n";
            }

            my $lexer      = $lexers->[$symbol_id];
            my $lexer_type = ref $lexer;
            croak("Illegal type for lexer: undefined")
                unless defined $lexer_type;

            pos $$input_ref = $pos;

            if ( $lexer_type eq "Regexp" ) {
                if ( $$input_ref =~ /$lexer/g ) {
                    my $match = $+{mArPa_match};

                    # my $prefix = $+{mArPa_prefix};
                    # my $suffix = $+{mArPa_suffix};
                    # my $length = length(${^MATCH});
                    my $length = ( pos $$input_ref ) - $pos;
                    croak(
                        "Internal error, zero length token -- this is a Marpa bug"
                    ) unless $length;
                    push( @alternatives, [ $lexable, $match, $length ] );
                    if ($trace_lex_matches) {
                        print $trace_fh
                            "Matched regex for ",
                            $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                            " at $pos: ", $match, "\n";
                    }
                    last LEXABLE unless $ambiguous_lex;
                }    # if match

                next LEXABLE;

            }    # if defined regex

            # If it's a lexable and a regex was not defined, there must be a
            # closure
            croak("Illegal type for lexer: $lexer_type")
                unless $lexer_type eq "ARRAY";

            my ($lex_closure, $prefix, $suffix) = @$lexer;
            if (defined $prefix) {
                $$input_ref =~ /\G$prefix/g;
            }

            my ( $match, $length );
            {
                my @warnings;
                local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
                eval { ($match, $length) = $lex_closure->($input_ref, $pos); };
                my $fatal_error = $@;
                if ($fatal_error or @warnings) {
                    Parse::Marpa::Internal::die_on_problems(
                        $fatal_error, \@warnings,
                        "user supplied lexer",
                        "user supplied lexer for "
                            . $lexable->[Parse::Marpa::Internal::Symbol::NAME]
                            .  " at $pos",
                        \($lexable->[Parse::Marpa::Internal::Symbol::ACTION])
                    );
                }
            }

            next LEXABLE if not defined $match;

            $length //= length $match;

            push( @alternatives, [ $lexable, $match, $length ] );
            if ($trace_lex_matches) {
                print $trace_fh
                    "Matched Closure for ",
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos: ", $match, "\n";
            }

            last LEXABLE unless $ambiguous_lex;

        }    # LEXABLE

        my $active = scan_set( $parse, @alternatives );

        return $pos unless $active;

    }    # POS

    return -1;

}    # sub text

sub Parse::Marpa::Recognizer::end_input {
    my $parse = shift;

    my (
        $grammar,
        $current_set,
        $last_completed_set,
        $furthest_earleme,
    ) = @{$parse}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::CURRENT_SET,
        Parse::Marpa::Internal::Recognizer::LAST_COMPLETED_SET,
        Parse::Marpa::Internal::Recognizer::FURTHEST_EARLEME,
    ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    return if $last_completed_set >= $furthest_earleme;

    EARLEY_SET: while ($current_set <= $furthest_earleme) {
        Parse::Marpa::Internal::Recognizer::complete_set($parse);
        $current_set++;
        $parse->[ Parse::Marpa::Internal::Recognizer::CURRENT_SET ] = $current_set;
    }
}

=begin Apolegetic:

It's bad style, but this routine is in a tight loop and for efficiency
I pull the token alternatives out of @_ one by one as I go in the code,
rather than at the beginning of the method.

The remaining arguments should be a list of token alternatives, as
array references.  The array for each alternative is (token, value,
length), where token is a symbol reference, value can anything
meaningful to the user, and length is the length of this token in
earlemes.

=end Apolegetic:

=cut

# Given a parse object and a list of alternative tokens starting at
# the current earleme, compute the Earley set for that earleme
sub scan_set {
    my $parse = shift;

    my ( $earley_set_list, $earley_hash_list, $grammar, $current_set,
        $furthest_earleme, $exhausted, )
        = @{$parse}[
        EARLEY_SETS,      EARLEY_HASHES, GRAMMAR, CURRENT_SET,
        FURTHEST_EARLEME, EXHAUSTED
        ];
    croak("Attempt to scan tokens on an exhausted parse") if $exhausted;
    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];

    my $earley_set = $earley_set_list->[$current_set];

    if ( not defined $earley_set ) {
        $earley_set_list->[$current_set] = [];
        if ( $current_set >= $furthest_earleme ) {
            $parse->[Parse::Marpa::Internal::Recognizer::EXHAUSTED] = $exhausted =
                1;
        }
        else {
            $parse->[CURRENT_SET]++;
        }
        return !$exhausted;
    }

    EARLEY_ITEM: for ( my $ix = 0; $ix < @$earley_set; $ix++ ) {

        my $earley_item = $earley_set->[$ix];
        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];

        # I allow ambigious tokenization.
        # Loop through the alternative tokens.
        ALTERNATIVE: for my $alternative (@_) {
            my ( $token, $value, $length ) = @$alternative;

            if ( $length <= 0 ) {
                croak(    "Token "
                        . $token->[Parse::Marpa::Internal::Symbol::NAME]
                        . " with bad length "
                        . $length );
            }

            # Make sure it's an allowed terminal symbol.
            # TODO: Must remember to be sure that
            # nulling symbols are never terminals
            unless ( $token->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
                my $name = $token->[Parse::Marpa::Internal::Symbol::NAME];
                croak(    "Non-terminal "
                        . ( defined $name ? "$name " : "" )
                        . "supplied as token" );
            }

            # compute goto(kernel_state, token_name)
            my $kernel_state =
                $SDFA->[ $state->[Parse::Marpa::Internal::SDFA::ID] ]
                ->[Parse::Marpa::Internal::SDFA::TRANSITION]
                ->{ $token->[Parse::Marpa::Internal::Symbol::NAME] };
            next ALTERNATIVE unless $kernel_state;

            # Create the kernel item and its link.
            my $target_ix = $current_set + $length;
            my $target_earley_hash =
                ( $earley_hash_list->[$target_ix] ||= {} );
            my $target_earley_set = ( $earley_set_list->[$target_ix] ||= [] );
            if ( $target_ix > $furthest_earleme ) {
                $parse->[Parse::Marpa::Internal::Recognizer::FURTHEST_EARLEME] =
                    $furthest_earleme = $target_ix;
            }
            my $key = pack( "JJ", $kernel_state, $parent );
            my $target_earley_item = $target_earley_hash->{$key};
            unless ( defined $target_earley_item ) {
                @{$target_earley_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKENS,
                    Parse::Marpa::Internal::Earley_item::SET
                    ]
                    = ( $kernel_state, $parent, 0, [], 0, [], $target_ix );
                $target_earley_hash->{$key} = $target_earley_item;
                push( @$target_earley_set, $target_earley_item );
            }
            push(
                @{  $target_earley_item
                        ->[Parse::Marpa::Internal::Earley_item::TOKENS]
                    },
                [ $earley_item, $value ]
            );

            my $resetting_state =
                $kernel_state->[Parse::Marpa::Internal::SDFA::TRANSITION]
                ->{""};
            next ALTERNATIVE unless defined $resetting_state;
            $key = pack( "JJ", $resetting_state, $target_ix );
            unless ( exists $target_earley_hash->{$key} ) {
                my $new_earley_item;
                @{$new_earley_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKENS,
                    Parse::Marpa::Internal::Earley_item::SET
                    ]
                    = ( $resetting_state, $target_ix, 0, [], 0, [],
                    $target_ix );
                $target_earley_hash->{$key} = $new_earley_item;
                push( @$target_earley_set, $new_earley_item );
            }

        }    # ALTERNATIVE

    }    # EARLEY_ITEM

    $parse->[CURRENT_SET]++;

    return 1;

}    # sub scan_set

sub complete_set {
    my $parse = shift;

    my ($earley_set_list,   $earley_hash_list,  $grammar,
        $current_set,       $furthest_earleme,  $exhausted,
        $lexables_by_state, $priorities,
        )
        = @{$parse}[
        EARLEY_SETS,       EARLEY_HASHES,
        GRAMMAR,           CURRENT_SET,
        FURTHEST_EARLEME,  EXHAUSTED,
        LEXABLES_BY_STATE,
        PRIORITIES,
        ];
    croak("Attempt to complete another earley set in an exhausted parse")
        if $exhausted;

    my $earley_set  = $earley_set_list->[$current_set];
    my $earley_hash = $earley_hash_list->[$current_set];

    $earley_set ||= [];

    my ( $SDFA, $symbols, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SDFA,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my ($trace_fh, $trace_completions);
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_completions 
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS ];
    }

    my $lexable_seen = [];
    $#$lexable_seen = $#$symbols;

    EARLEY_ITEM: for ( my $ix = 0; $ix < @$earley_set; $ix++ ) {

        my $earley_item = $earley_set->[$ix];
        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];
        my $state_id = $state->[Parse::Marpa::Internal::SDFA::ID];

        for my $lexable ( @{ $lexables_by_state->[$state_id] } ) {
            $lexable_seen->[$lexable] = 1;
        }

        next EARLEY_ITEM if $current_set == $parent;

        COMPLETE_RULE:
        for my $complete_symbol_name (
            @{ $state->[Parse::Marpa::Internal::SDFA::COMPLETE_LHS] } )
        {
            PARENT_ITEM:
            for my $parent_item ( @{ $earley_set_list->[$parent] } ) {
                my ( $parent_state, $grandparent ) = @{$parent_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT
                ];
                my $kernel_state =
                    $SDFA->[ $parent_state->[Parse::Marpa::Internal::SDFA::ID]
                    ]->[Parse::Marpa::Internal::SDFA::TRANSITION]
                    ->{$complete_symbol_name};
                next PARENT_ITEM unless defined $kernel_state;

                my $key = pack( "JJ", $kernel_state, $grandparent );
                my $target_earley_item = $earley_hash->{$key};
                unless ( defined $target_earley_item ) {
                    @{$target_earley_item}[
                        Parse::Marpa::Internal::Earley_item::STATE,
                        Parse::Marpa::Internal::Earley_item::PARENT,
                        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                        Parse::Marpa::Internal::Earley_item::LINKS,
                        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                        Parse::Marpa::Internal::Earley_item::TOKENS,
                        Parse::Marpa::Internal::Earley_item::SET
                        ]
                        = (
                        $kernel_state, $grandparent, 0, [], 0, [],
                        $current_set
                        );
                    $earley_hash->{$key} = $target_earley_item;
                    push( @$earley_set, $target_earley_item );
                }
                push(
                    @{  $target_earley_item
                            ->[Parse::Marpa::Internal::Earley_item::LINKS]
                        },
                    [ $parent_item, $earley_item ]
                );

                my $resetting_state =
                    $kernel_state->[Parse::Marpa::Internal::SDFA::TRANSITION]
                    ->{""};
                next PARENT_ITEM unless defined $resetting_state;
                $key = pack( "JJ", $resetting_state, $current_set );
                unless ( defined $earley_hash->{$key} ) {
                    my $new_earley_item;
                    @{$new_earley_item}[
                        Parse::Marpa::Internal::Earley_item::STATE,
                        Parse::Marpa::Internal::Earley_item::PARENT,
                        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                        Parse::Marpa::Internal::Earley_item::LINKS,
                        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                        Parse::Marpa::Internal::Earley_item::TOKENS,
                        Parse::Marpa::Internal::Earley_item::SET
                        ]
                        = (
                        $resetting_state, $current_set, 0, [], 0, [],
                        $current_set
                        );
                    $earley_hash->{$key} = $new_earley_item;
                    push( @$earley_set, $new_earley_item );
                }

            }    # PARENT_ITEM

        }    # COMPLETE_RULE

    }    # EARLEY_ITEM

    EARLEY_ITEM: for my $earley_item (@$earley_set) {
        my $links =
            $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS];
        my @sorted_links =
            map  { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map {
            [   $_,
                $priorities->[
                    $_->[1]->[Parse::Marpa::Internal::Earley_item::STATE]
                    ->[Parse::Marpa::Internal::SDFA::ID]
                ]
            ]
            } @$links;
        $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS] =
            \@sorted_links;
    }

    # TODO: Prove that the completion links are UNIQUE

    # Free memory for the hash
    $earley_hash_list->[$current_set] = undef;

    $parse->[Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET] = $current_set;
    $parse->[Parse::Marpa::Internal::Recognizer::LAST_COMPLETED_SET] = $current_set;

    if ($trace_completions) {
        print $trace_fh Parse::Marpa::show_earley_set($earley_set);
    }

    # Dream up some efficiency hack here.  Memoize sorted lexables by state?
    my $lexables = [
        sort {
            $a->[Parse::Marpa::Internal::Symbol::PRIORITY]
                <=> $b->[Parse::Marpa::Internal::Symbol::PRIORITY]
            }
            map { $symbols->[$_] }
            grep { $lexable_seen->[$_] } ( 0 .. $#$symbols )
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
    for (
        my $earleme = $last_earleme;
        $earleme >= $start_earleme;
        $earleme--
        )
    {
        my $earley_set = $earley_sets->[$earleme];

        ITEM: for my $earley_item (@$earley_set) {
            my ( $state, $parent ) = @{$earley_item}[
                Parse::Marpa::Internal::Earley_item::STATE,
                Parse::Marpa::Internal::Earley_item::PARENT,
            ];
            next ITEM unless $parent == $start_earleme;
            if ( defined $symbol ) {
                my $complete_rules =
                    $state->[Parse::Marpa::Internal::SDFA::COMPLETE_RULES]
                    ->{$symbol};
                next ITEM unless $complete_rules;
            }
            my $complete_lhs =
                $state->[Parse::Marpa::Internal::SDFA::COMPLETE_LHS];
            next ITEM unless scalar @$complete_lhs;
            return ( $earleme, $complete_lhs );
        }    # ITEM
    }    # EARLEME
    return;
}

1;

=pod

=head1 NAME

Parse::Marpa::Recognizer - A Marpa Recognizer Object

=head1 SYNOPSIS

    my $recce = new Parse::Marpa::Recognizer({
	grammar => $grammar,
    });

    my $fail_offset = $recce->text(\("2-0*3+1"));
    if ($fail_offset >= 0) {
       die("Parse failed at offset $fail_offset");
    }

Z<>

    my $recce2 = Parse::Marpa::Recognizer::new({grammar => $grammar});

    my $op = $grammar->get_symbol("op");
    my $number = $grammar->get_symbol("number");
    $recce2->earleme([$number, 2, 1]);
    $recce2->earleme([$op, "-", 1]);
    $recce2->earleme([$number, 0, 1]);
    $recce2->earleme([$op, "*", 1]);
    $recce2->earleme([$number, 3, 1]);
    $recce2->earleme([$op, "+", 1]);
    $recce2->earleme([$number, 1, 1]);
    $recce2->end_input();

=head1 DESCRIPTION

Marpa parsing takes place in three major phases: grammar creation, input recognition
and parse evaluation.
Once a grammar has rules and is precomputed, a recognizer can be created from it.
The recognizer accepts input and
can be used to create a Marpa evaluator object.

=head2 Tokens and Earlemes

Marpa allows ambiguous tokens.
Several Marpa tokens can start at a single parsing location.
Marpa tokens can be of various lengths.
Marpa tokens can even overlap.

For most parsers, their idea of position is a location in a token stream.
To deal with variable-length and overlapping tokens,
Marpa needs a more flexible idea of location.
This flexibility is provided by tracking parse position in B<earlemes>,
which are named in honor of Jay Earley, the inventor of the algorithm
on which Marpa is based.

If you do your lexing with the C<text> method, you will use a
one-character-per-earleme model.
That is, input will be treated as a string,
and, each earleme will be a character location in that string.
If you set up your terminals using MDL,
Marpa assumes that you will be using the C<text> method and one-character-per-earleme
matching.

Marpa is not restricted to the one-character-per-earleme model.
With the C<earleme> method, you can structure your input in almost any way you like.
You could, for example, create a token stream and use a one-token-per-earleme model,
and this would be equivalent to the standard way of doing things.
You can also structure your input in other, special ways to suit your application.

There are only two restrictions in mapping tokens to earlemes:

=over 4

=item 1

Tokens must be scanned in earleme order.
That is, all the tokens at earleme C<N>
must be recognized before any token at earleme C<N+1>.

=item 2

Tokens cannot be zero or negative in earleme length.

=back

A parse is said to start at earleme 0, and "earleme I<N>" means the location I<N> earlemes
after earleme 0.
B<Length> in earlemes probably means what you expect it does.
The length from earleme 3 to earleme 6,
for instance, is 3 earlemes.

The tokens C<text> recognizes are fed to the Marpa parse engine.
The earleme length of each token is
set using the token's earleme length.
(If a token has a "lex prefix",
the length of the lex prefix counts as part of the token length.)

=head3 Parse Exhaustion

In conventional Earley parsing,
a parse is exhausted as soon as the parser reaches a "location"
without a token.
Because Marpa parses in terms of earlemes
and tokens can span many earlemes,
parses in Marpa remain active even if they reach an "empty earleme".
In fact, Marpa parses often contain many stretches
of empty earlemes, and some of these stretches can be quite long.

In Marpa, a parse remains active if some token
has been recognized which B<ends> at or after the current earleme.
A Marpa parse is not exhausted until

=over 4

=item * No token starts at the current earleme, and

=item * No token ends at or after the current earleme.

=back

=head3 Note to Experts

Those of you already familiar with Earley parsing
and its standard
terminology
may find the following helpful:

=over

=item * Each "earleme" correspond to an Earley set in the usual terminology.

=item * In the usual terminology, an "empty earleme" would be an Earley set with no Earley items.

=back

=head1 METHODS

=head2 new

    my $recce = new Parse::Marpa::Recognizer({
       grammar=> $g,
       preamble => $new_preamble,
    });

C<Parse::Marpa::Recognizer::new> takes as its arguments a hash reference containing named
arguments.
It returns a new parse object or throws an exception.
Either the C<compiled_grammar> or the C<grammar> option must be specified, but not both.
A recognizer is created with the default end of parsing set to earleme 0,
which is before any input.

If the C<grammar> option is specified, 
its value must be a grammar object with rules defined.
If it is not precomputed, C<new> will precompute it.
A deep copy of the grammar is then made to be used in the recognizer.

If the C<compiled_grammar> option is specified, 
its value must be a Perl 5 string containing a compiled Marpa grammar,
as produced by L<C<Parse::Marpa::Grammar::compile>|Parse::Marpa::Grammar/"compile">.
It will be decompiled for use in the recognizer.

Marpa options are also
valid named arguments.
For these, see L<Parse::Marpa/OPTIONS>.

=head2 text

    local($RS) = undef;
    my $spec = <FH>;
    my $fail_offset = $recce->text(\$spec);
    if ($fail_offset >= 0) {
       die("Parse failed at offset $fail_offset");
    }

Extends the parse in the one-character-per-earleme model.
The one, required, argument must be
a B<reference> to a string containing the text to be parsed.
If the parse is active after the text has been processed,
the default end of parsing is set to the end of the text,
and -1 is returned.

If the parse is exhausted by the input, that is, if processing reaches
a point where no successful parse is possible,
the default end of parsing is set to the earleme at which the parse was
exhausted,
and the character offset at which the parse was exhausted is returned.
A zero return means that the parse was exhausted at character offset zero.
Failures, other than exhausted parses, are thrown as exceptions.

When you use the C<text> method for input,
earlemes correspond one-to-one to characters in the text.
The earleme number is always one more than the character offset
from the start of text.
The first character is at earleme one and offset zero.
Terminals are recognized in the text
using the lexers that were specified in the porcelain
or the plumbing.

=head2 earleme

    my $op = $grammar->get_symbol("op");
    $recce2->earleme([$op, "-", 1]);

The C<earleme> method takes zero or more arguments.
Each argument is a token which starts at the B<current earleme>.
Every call to the C<earleme> method moves the current earleme forward by one earleme.

More than one token may be added at an each earleme,
because ambiguous lexing is allowed.
Each token is a reference to a three element array.
The first element is a "cookie" for the token's symbol,
as returned by the C<Parse::Marpa::get_symbol> method,
or the C<get_symbol> method of a porcelain interface.
The second element is the token's value in the parse.
The third is the token's length in earlemes.

The C<earleme> method first checks to see if the parse is still B<active>,
that is,
if it is still possible for the parse to succeed.
If the parse is active,
the tokens are added.
The default end of parsing is set to the current earleme,
after which the current earleme is advanced by one.
If the C<earleme> method is called without any arguments,
both the current earleme and the default end of parsing will be incremented one earleme,
but no new tokens are added.

An earleme remains the current earleme during only one call of the C<earleme> method.
All tokens starting at that earleme must be added in that call.
The first time that the C<earleme> method is called in a recognizer,
the current earleme is at earleme 0.

If no parses are possible, the parse is said to be B<exhausted>.
If the B<earleme> method is called on an exhausted parse,
it returns 0.
The default end of parse remains where it was,
at the last earleme at which the parse was active.
The C<earleme> method throws an exception on other failures.

This is the low-level token input method, and allows maximum
control over the form and interrelationship of tokens.
No model of the relationship between the tokens and the earlemes is assumed.
The user is free to invent her own.

=head2 end_input

    $recce2->end_input();

This method takes no arguments.
It is used with the C<earleme> method in offline mode, to signal
the end of input.
The input is processed out to the last earleme at which a token ends,
and the default end of parsing is set to that earleme.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
