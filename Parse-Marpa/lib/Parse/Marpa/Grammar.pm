package Parse::Marpa::Internal;

use 5.010_000;

use warnings;
no warnings "recursion";
use strict;

=begin Implementation:

Structures and Objects: The design is to present an object-oriented
interface, but internally to avoid overheads.  So internally, where
objects might be used, I use array with constant indices to imitate
what in C would be structures.

=end Implementation:

=cut

# It's all integers, except for the version number
use integer;

package Parse::Marpa::Internal;

use Parse::Marpa::Offset Symbol =>
    qw(ID NAME LHS RHS ACCESSIBLE PRODUCTIVE START REGEX NULLING NULLABLE NULL_VALUE NULL_ALIAS
        TERMINAL CLOSURE PRIORITY COUNTED ACTION PREFIX SUFFIX IS_CHAF_NULLING);

# LHS             - rules with this as the lhs,
#                   as a ref to an array of rule refs
# RHS             - rules with this in the rhs,
#                   as a ref to an array of rule refs
# ACCESSIBLE      - reachable from start symbol?
# PRODUCTIVE      - reachable from input symbol?
# START           - is one of the start symbols?
# REGEX           - regex, for terminals; undef otherwise
# NULLING         - always is null?
# NULLABLE        - can match null?
# NULL_VALUE      - value when null
# NULL_ALIAS      - for a non-nullable symbol,
#                   ref of a its nulling alias,
#                   if there is one
#                   otherwise undef
# TERMINAL        - terminal?
# CLOSURE         - closure to do lexing
# PRIORITY        - order, for lexing
# COUNTED         - used on rhs of counted rule?
# ACTION          - lexing action specified by user
# PREFIX          - lexing prefix specified by user
# SUFFIX          - lexing suffix specified by user
# IS_CHAF_NULLING - if CHAF nulling lhs, ref to array
#                   of rhs symbols

use Parse::Marpa::Offset Rule =>
    qw(ID NAME LHS RHS NULLABLE ACCESSIBLE PRODUCTIVE NULLING USEFUL ACTION
        CLOSURE ORIGINAL_RULE HAS_CHAF_LHS HAS_CHAF_RHS PRIORITY CODE CYCLE);

=begin Implementation:

LHS - ref of the left hand symbol
RHS - array of symbol refs
NULLABLE - can match null?
ACCESSIBLE - reachable from start symbol?
PRODUCTIVE - reachable from input symbol?
NULLING - always matches null?
USEFUL - use this rule in NFA?
ACTION - action for this rule as specified by user
CLOSURE - closure for evaluating this rule
ORIGINAL_RULE - for a rewritten rule, the original
HAS_CHAF_LHS  - has CHAF internal symbol as lhs?
HAS_CHAF_RHS - has CHAF internal symbol on rhs?
PRIORITY - rule priority
CODE - code used to create closure
CYCLE - is this rule part of a cycle?

=end Implementation:

=cut

use Parse::Marpa::Offset NFA =>
    qw(ID NAME ITEM TRANSITION AT_NULLING COMPLETE PRIORITY);

=begin Implementation:

ITEM - an LR(0) item
TRANSITION - the transitions, as a hash from symbol name to NFA states
AT_NULLING - dot just before a nullable symbol?
COMPLETE - rule is complete?
PRIORITY - rule priority

=end Implementation:

=cut

use Parse::Marpa::Offset QDFA =>
    qw(ID NAME NFA_STATES TRANSITION COMPLETE_LHS
        COMPLETE_RULES START_RULE TAG RESET_ORIGIN PRIORITY);

=begin Implementation:

NFA_STATES     - in an QDFA: an array of NFA states
TRANSITION     - the transitions, as a hash
               - from symbol name to references to arrays
               - of QDFA states
COMPLETE_LHS   - an array of the lhs's of complete rules
COMPLETE_RULES - an array of lists of the complete rules,
               - indexed by lhs
START_RULE     - the start rule
TAG            - implementation-independant tag
RESET_ORIGIN   - reset origin for this state?
PRIORITY       - priority of this state

=end Implementation:

=cut

use Parse::Marpa::Offset LR0_item => qw(RULE POSITION);

use Parse::Marpa::Offset Grammar =>
    qw(ID NAME RULES SYMBOLS RULE_HASH SYMBOL_HASH
        START NFA QDFA QDFA_BY_NAME NULLABLE_SYMBOL ACADEMIC DEFAULT_NULL_VALUE
        DEFAULT_ACTION DEFAULT_LEX_PREFIX DEFAULT_LEX_SUFFIX AMBIGUOUS_LEX
        TRACE_RULES TRACE_FILE_HANDLE LOCATION_CALLBACK OPAQUE PROBLEMS
        PREAMBLE LEX_PREAMBLE WARNINGS VERSION CODE_LINES SEMANTICS
        TRACING TRACE_STRINGS TRACE_PREDEFINEDS TRACE_PRIORITIES TRACE_LEX_TRIES
        TRACE_LEX_MATCHES TRACE_ITERATIONS TRACE_COMPLETIONS TRACE_ACTIONS TRACE_VALUES
        MAX_PARSES ONLINE ALLOW_RAW_SOURCE PHASE INTERFACE START_STATES
        CYCLE_ACTION CYCLE_DEPTH);

=begin Implementation:

ID                 - number of this grammar
NAME               - namespace special to this grammar
                     it should only be used BEFORE compilation, because it's not
                     guaranteed unique after decompilation
RULES              - array of rule refs
SYMBOLS            - array of symbol refs
RULE_HASH          - hash by name of rule refs
SYMBOL_HASH        - hash by name of symbol refs
START              - ref to start symbol
NFA                - array of states
QDFA               - array of states
QDFA_BY_NAME       - hash from QDFA name to QDFA reference
NULLABLE_SYMBOL    - array of refs of the nullable symbols
ACADEMIC           - true if this is a textbook grammar,
                   - for checking the NFA and QDFA, and NOT
                   - for actual Earley parsing
DEFAULT_NULL_VALUE - default value for nulling symbols
DEFAULT_ACTION     - action for rules without one
DEFAULT_LEX_PREFIX - default prefix for lexing
DEFAULT_LEX_SUFFIX - default suffix for lexing
AMBIGUOUS_LEX      - lex ambiguously?
LOCATION_CALLBACK  - default callback for showing location
OPAQUE - default for opacity
PROBLEMS - fatal problems
PREAMBLE - evaluation preamble
LEX_PREAMBLE - lex preamble
WARNINGS - print warnings about grammar?
VERSION - Marpa version this grammar was compiled from
CODE_LINES - max lines to display on failure
SEMANTICS - semantics (currently perl5 only)
TRACING - master flag, set if any tracing is being done
    (to control overhead for non-tracing processes)
TRACE_STRINGS - trace strings defined in marpa grammar
TRACE_PREDEFINEDS - trace predefineds in marpa grammar
PHASE - the grammar's phase
INTERFACE - the grammar's interface
START_STATES - ref to array of the start states
CYCLE_ACTION - ref to array of the start states
CYCLE_DEPTH - depth to which to follow cycles

=end Implementation:

=cut

# values for grammar interfaces
use Parse::Marpa::Offset Interface => qw(RAW MDL);

sub Parse::Marpa::Internal::Interface::description {
    my $interface = shift;
    given ($interface) {
        when (Parse::Marpa::Internal::Interface::RAW) { return 'raw interface' }
        when (Parse::Marpa::Internal::Interface::MDL) { return 'Marpa Description Language interface' }
    }
    return 'unknown interface';
}

# values for grammar phases
use Parse::Marpa::Offset Phase =>
    qw(NEW RULES PRECOMPUTED COMPILED EVALED IN_USE);

sub Parse::Marpa::Internal::Phase::description {
    my $phase = shift;
    given ($phase) {
        when (Parse::Marpa::Internal::Phase::NEW)         { return 'grammar without rules' }
        when (Parse::Marpa::Internal::Phase::RULES)       { return 'grammar with rules entered' }
        when (Parse::Marpa::Internal::Phase::PRECOMPUTED) { return 'precomputed grammar' }
        when (Parse::Marpa::Internal::Phase::COMPILED)    { return 'compiled grammar' }
        when (Parse::Marpa::Internal::Phase::EVALED)      { return 'evaled grammar' }
        when (Parse::Marpa::Internal::Phase::IN_USE)      { return 'in use grammar' }
    }
    return 'unknown phase';
}

package Parse::Marpa::Internal::Grammar;

use Scalar::Util qw(weaken);
use Data::Dumper;

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

sub Parse::Marpa::Internal::code_problems {
    my $fatal_error   = shift;
    my $warnings      = shift;
    my $where         = shift;
    my $long_where    = shift;
    my $code          = shift;
    my $caller_return = shift;
    my ( $package, $filename, $problem_line ) = @{$caller_return};

    $long_where //= $where;
    my $grammar = $Parse::Marpa::Internal::This::grammar;
    my @msg;
    my $code_lines;
    if ( defined $grammar ) {
        $code_lines = $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES];
    }
    else {
        push @msg, 'Marpa bug: Grammar not set';
    }

    # if we have code
    my $code_to_print;

    # block to look for the code to print
    CODE_TO_PRINT: {

        last CODE_TO_PRINT unless defined $code;
        last CODE_TO_PRINT unless defined ${$code};

        $code_lines //= 3;

        # if code_lines < 0, print all lines
        if ( $code_lines < 0 ) {
            $code_to_print = $code;
            last CODE_TO_PRINT;
        }

        # which lines to print?
        my $first_line;
        my $max_line;

        # else if we know the problem line, print code_lines
        # worth of context
        if ( defined $problem_line ) {
            $first_line = $problem_line - $code_lines;
            $first_line = 1 if $first_line < 1;
            $max_line   = $problem_line + $code_lines;

            # else print the first 2*code_lines+1 lines
        }
        else {
            $first_line = 1;
            $max_line   = $code_lines * 2 + 1;
        }

        # go up to start of first line
        my $position = 0;

        # remember that lines are numbered starting at 1
        my $line = 1;
        LINE: while ( $line < $first_line ) {
            $position = index ${$code}, "\n", $position;
            $position++;
            $line++;
        }

        # now create an array of the lines to print
        my @lines;
        LINE: while ( $line <= $max_line ) {
            my $start = $position;
            $position = index ${$code}, "\n", $start;
            if ( $position < 0 ) {
                if ( $start < length ${$code} ) {
                    push @lines, (substr ${$code}, $start, 72 );
                }
                last LINE;
            }
            $position++;
            push @lines, (substr ${$code}, $start, ( $position - $start ) );
            $line++;
        }

        my $line_labeled_code = '';
        LINE: for my $i ( 0 .. $#lines ) {
            my $line_number = $first_line + $i;
	    my $marker = q{};
	    $marker = "*"
		if defined $problem_line and $problem_line == $line_number;
            $line_labeled_code .= "$marker$line_number: " . $lines[$i];
        }
        $code_to_print = \$line_labeled_code;
    }

    # If we have a section of code to print
    if ( defined $code_to_print ) {
        chomp ${$code_to_print};
        push @msg,
                  'Problems in '
                . $long_where
                . ", code:\n"
                . ${$code_to_print}
                . "\n";
    }

    my $warnings_count = @{$warnings};
    if ($warnings_count) {
        push @msg, "Warnings ($warnings_count) in $where:\n", @{$warnings};
        unless ($fatal_error) {
            $fatal_error = 'Marpa will not continue due to warnings';
        }
    }
    push @msg, "Fatal problem in $long_where\n", $fatal_error;
    croak(@msg);
}

package Parse::Marpa::Internal::Source_Eval;

sub Parse::Marpa::Internal::Grammar::raw_grammar_eval {
    my $grammar     = shift;
    my $raw_grammar = shift;

    my ( $trace_fh, $trace_strings, $trace_predefineds );
    if ( $grammar->[Parse::Marpa::Internal::Grammar::TRACING] ) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_strings =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_STRINGS];
        $trace_predefineds =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_PREDEFINEDS];
    }

    my $new_start_symbol;
    my $new_semantics;
    my $new_version;
    my $new_preamble;
    my $new_lex_preamble;
    my $new_default_lex_prefix;
    my $new_default_action;
    my $new_default_null_value;
    my $new_rules;
    my $new_terminals;
    my %strings;

    {
        my @warnings;
        my @caller_return;
        local $SIG{__WARN__} = sub {
	    my $warning = $_[0];
            push @warnings, $warning;
            @caller_return = caller 0;
        };
        eval ${$raw_grammar};
        my $fatal_error = $@;
        if ( $fatal_error or @warnings ) {
            Parse::Marpa::Internal::code_problems(
                $fatal_error, \@warnings,
                'evaluating gramar',
                'evaluating gramar',
                $raw_grammar, \@caller_return
            );
        }
    }

    if ($trace_strings) {
        for my $string ( keys %strings ) {
            say $trace_fh qq{String "$string" set to '}, $strings{$string},
                q{'};
        }
    }

    if ( defined $new_start_symbol ) {
        $grammar->[Parse::Marpa::Internal::Grammar::START] =
            $new_start_symbol;
        say $trace_fh 'Start symbol set to ', $new_start_symbol
            if $trace_predefineds;
    }

    Carp::croak('Semantics must be set to perl5 in marpa grammar')
        if not defined $new_semantics
            or $new_semantics ne 'perl5';
    $grammar->[Parse::Marpa::Internal::Grammar::SEMANTICS] = $new_semantics;
    say $trace_fh 'Semantics set to ', $new_semantics
        if $trace_predefineds;

    Carp::croak('Version must be set in marpa grammar')
        if not defined $new_version;

    no integer;
    Carp::croak(
        "Version in marpa grammar ($new_version) does not match Marpa (",
        $Parse::Marpa::VERSION, ')' )
        if $new_version != $Parse::Marpa::VERSION;
    use integer;

    $grammar->[Parse::Marpa::Internal::Grammar::VERSION] = $new_version;
    say $trace_fh 'Version set to ', $new_version
        if $trace_predefineds;

    if ( defined $new_lex_preamble ) {
        $grammar->[Parse::Marpa::Internal::Grammar::LEX_PREAMBLE] = $new_lex_preamble;
        say $trace_fh q{Lex preamble set to '}, $new_lex_preamble, q{'}
            if defined $trace_predefineds;
    }

    if ( defined $new_preamble ) {
        $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE] = $new_preamble;
        say $trace_fh q{Preamble set to '}, $new_preamble, q{'}
            if defined $trace_predefineds;
    }

    if ( defined $new_default_lex_prefix ) {
        $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] =
            $new_default_lex_prefix;
        say $trace_fh q{Default lex prefix set to '}, $new_default_lex_prefix,
            q{'}
            if defined $trace_predefineds;
    }

    if ( defined $new_default_action ) {
        $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION] =
            $new_default_action;
        say $trace_fh q{Default action set to '}, $new_default_action, q{'}
            if $trace_predefineds;
    }

    if ( defined $new_default_null_value ) {
        $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE] =
            $new_default_null_value;
        say $trace_fh q{Default null_value set to '}, $new_default_null_value,
            q{'}
            if $trace_predefineds;
    }

    Parse::Marpa::Internal::Grammar::add_user_rules( $grammar, $new_rules );
    Parse::Marpa::Internal::Grammar::add_user_terminals( $grammar,
        $new_terminals );

    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::RULES;
    $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE] =
        Parse::Marpa::Internal::Interface::RAW;

    return;
}

package Parse::Marpa::Internal::Grammar;

sub Parse::Marpa::Grammar::new {
    my $class = shift;
    my ($args) = @_;
    $args //= {};

    my $grammar = [];
    bless $grammar, $class;
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    # set the defaults and the default defaults
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE] = *STDERR;
    state $grammar_number = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::ID] = $grammar_number++;

    # Note: this limits the number of grammar to the number of integers --
    # not likely to be a big problem.
    $grammar->[Parse::Marpa::Internal::Grammar::NAME] =
        sprintf 'Parse::Marpa::G_%x', $grammar_number;

    $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC]           = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] = q{};
    $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX] = q{};
    $grammar->[Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX]      = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_RULES]        = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_VALUES]       = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_ITERATIONS]   = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::LOCATION_CALLBACK] =
        q{ 'Earleme ' . $earleme };
    $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE]     = undef;
    $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS]   = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::CYCLE_ACTION]   = 'warn';
    $grammar->[Parse::Marpa::Internal::Grammar::CYCLE_DEPTH]    = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] = undef;
    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::NEW;
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS]      = [];
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH]  = {};
    $grammar->[Parse::Marpa::Internal::Grammar::RULES]        = [];
    $grammar->[Parse::Marpa::Internal::Grammar::RULE_HASH]    = {};
    $grammar->[Parse::Marpa::Internal::Grammar::QDFA_BY_NAME] = {};
    $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES]   = -1;
    $grammar->[Parse::Marpa::Internal::Grammar::ONLINE]       = 0;

    return $grammar->set($args);
}

sub Parse::Marpa::show_source_grammar_status {
    my $status =
        $Parse::Marpa::Internal::compiled_source_grammar ? 'Compiled' : 'Raw';
    if ($Parse::Marpa::Internal::compiled_eval_error) {
        $status .= "\nCompiled source had error:\n"
            . $Parse::Marpa::Internal::compiled_eval_error;
    }
    return $status;
}

# For use some day to make locator() more efficient on repeated calls
sub binary_search {
    my ( $target, $data ) = @_;
    my ( $lower, $upper ) = ( 0, $#{$data} );
    my $i;
    while ( $lower <= $upper ) {
        my $i = int +( ( $lower + $upper ) / 2 );
        given ( $data->[$i] ) {
            when ( $_ < $target ) { $lower = $i; }
            when ( $_ > $target ) { $upper = $i; }
            default               { return $i };
        }
    }
    return $lower;
}

sub locator {
    my $earleme = shift;
    my $string  = shift;

    my $lines;
    $lines //= [0];
    my $pos = pos ${$string} = 0;
    NL: while ( ${$string} =~ /\n/g ) {
        $pos = pos ${$string};
        push @{$lines}, $pos;
        last NL if $pos > $earleme;
    }
    my $line = (@{$lines}) - ( $pos > $earleme ? 2 : 1 );
    my $line_start = $lines->[$line];
    return ( $line, $line_start );
}

sub Parse::Marpa::show_location {
    my $msg     = shift;
    my $source  = shift;
    my $earleme = shift;

    my ( $line, $line_start ) = locator( $earleme, $source );
    my @msg = ( $msg, ' at line ', $line + 1, ", earleme $earleme\n" );
    given ( index ${$source}, "\n", $line_start ) {
        when (undef) { push @msg, (substr ${$source}, $line_start ), "\n" }
        default {
            push @msg,
                (substr ${$source}, $line_start, $_ - $line_start ), "\n";
        }
    }
    return join q{}, @msg, ( q{ } x ( $earleme - $line_start ) ), "^\n";
}

sub die_with_parse_failure {
    my $source  = shift;
    my $earleme = shift;

    croak( Parse::Marpa::show_location( 'Parse failed', $source, $earleme ) );
}

# The following method fails if "use Parse::Marpa::Raw_Source" is not
# specified by the user.  This is an undocumented bootstrapping routine,
# not having the "use" in this code saves a few cycles in the normal case.
# Also, forcing the user to be specific about the fact he's doing bootstrapping,
# seems like a good idea in itself.

sub Parse::Marpa::create_compiled_source_grammar {

    # Overwrite the existing compiled source grammar, if we already have one
    # This allows us to bootstrap in a new version

    my $raw_source_grammar = Parse::Marpa::Internal::raw_source_grammar();
    my $raw_source_version =
        $raw_source_grammar->[Parse::Marpa::Internal::Grammar::VERSION];
    if ( $raw_source_version != $Parse::Marpa::VERSION ) {
        croak(
            "raw source grammar version ($raw_source_version) does not match Marpa version (",
            $Parse::Marpa::VERSION, ')'
        );
    }
    $raw_source_grammar->precompute();
    return $raw_source_grammar->compile();
}

# Build a grammar from an MDL description.
# First arg is the grammar being built.
# Second arg is ref to string containing the MDL description.
sub parse_source_grammar {
    my $grammar        = shift;
    my $source         = shift;
    my $source_options = shift;

    my $trace_fh =
        $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    my $allow_raw_source =
        $grammar->[Parse::Marpa::Internal::Grammar::ALLOW_RAW_SOURCE];
    if ( not defined $Parse::Marpa::Internal::compiled_source_grammar ) {
        if ($allow_raw_source) {
            $Parse::Marpa::Internal::compiled_source_grammar =
                Parse::Marpa::create_compiled_source_grammar();
        }
        else {
            my $eval_error = $Parse::Marpa::Internal::compiled_eval_error
                // 'no eval error';
            croak( "No compiled source grammar:\n", $eval_error );
        }
    }

    # my $grammar_version = $source_grammar->[ Parse::Marpa::Internal::Grammar::VERSION ];
    # no integer;
    # if ($Parse::Marpa::VERSION != $grammar_version) {
    # croak("Version mismatch between Marpa ($Parse::Marpa::VERSION) and its source grammar ($grammar_version)");
    # }
    # use integer;

    $source_options //= {};

    my $recce = new Parse::Marpa::Recognizer(
        {   compiled_grammar =>
                $Parse::Marpa::Internal::compiled_source_grammar,
            trace_file_handle => $trace_fh,
            %{$source_options}
        }
    );

    my $failed_at_earleme = $recce->text($source);
    if ( $failed_at_earleme >= 0 ) {
        die_with_parse_failure( $source, $failed_at_earleme );
    }
    my $evaler = new Parse::Marpa::Evaluator($recce);
    croak("Marpa Internal error: failed to create evaluator for MDL") unless defined $evaler;
    my $value = $evaler->value();
    raw_grammar_eval( $grammar, $value );
    return;
}

sub Parse::Marpa::Grammar::set {
    my $grammar = shift;
    my ($args) = @_;
    $args //= {};

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];

    # set trace_fh even if no tracing, because we may turn it on in this method
    my $trace_fh =
        $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];

    my $phase     = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    my $interface = $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];

    # value of source needs to be a *REF* to a string
    my $source = $args->{'mdl_source'};
    if ( defined $source ) {
        croak('Cannot source grammar with some rules already defined')
            if $phase != Parse::Marpa::Internal::Phase::NEW;
        croak('Source for grammar must be specified as string ref')
            unless ref $source eq 'SCALAR';
        croak('Source for grammar undefined')
            if not defined ${$source};
        parse_source_grammar( $grammar, $source, $args->{'source_options'} );
        delete $args->{'mdl_source'};
        delete $args->{'source_options'};
    }

    while ( my ( $option, $value ) = each %{$args} ) {
        given ($option) {
            when ('rules') {
                $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE] //=
                    Parse::Marpa::Internal::Interface::RAW;
                my $interface =
                    $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];
                croak( 'rules option not allowed with '
                        . interface_description($interface) )
                    if $interface ne Parse::Marpa::Internal::Interface::RAW;
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                add_user_rules( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
                    Parse::Marpa::Internal::Phase::RULES;
            }
            when ('terminals') {
                $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE] //=
                    Parse::Marpa::Internal::Interface::RAW;
                my $interface =
                    $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];
                croak( 'terminals option not allowed with '
                        . interface_description($interface) )
                    if $interface ne Parse::Marpa::Internal::Interface::RAW;
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                add_user_terminals( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
                    Parse::Marpa::Internal::Phase::RULES;
            }
            when ('start') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::START] = $value;
            }
            when ('academic') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] =
                    $value;
            }
            when ('default_null_value') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE] =
                    $value;
            }
            when ('default_action') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION] =
                    $value;
            }
            when ('default_lex_prefix') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] =
                    $value;
            }
            when ('default_lex_suffix') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX] =
                    $value;
            }
            when ('ambiguous_lex') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX] =
                    $value;
            }
            when ('trace_file_handle') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE]
                    = $value;
            }
            when ('trace_actions') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_ACTIONS] =
                    $value;
                if ($value) {
                    say $trace_fh "Setting $option option";
                    say $trace_fh
                        "Warning: setting $option option after semantics were finalized"
                        if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_lex') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES] =
                    $grammar
                    ->[Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES] =
                    $value;
                if ($value) {
                    say $trace_fh "Setting $option option";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_lex_tries') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES] =
                    $value;
                if ($value) {
                    say $trace_fh "Setting $option option";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_lex_matches') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES]
                    = $value;
                if ($value) {
                    say $trace_fh "Setting $option option";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_values') {
		croak("trace_values must be set to a number >= 0")
		    unless $value =~ /^\d+$/;
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_VALUES] =
                    $value + 0;
                if ($value) {
                    say $trace_fh "Setting $option option to $value";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_rules') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_RULES] =
                    $value;
                if ($value) {
                    my $rules =
                        $grammar->[Parse::Marpa::Internal::Grammar::RULES];
                    my $rule_count = @{$rules};
                    say $trace_fh "Setting $option";
                    say $trace_fh
                        "Warning: Setting $option when $rule_count rules already exist"
                        if $rule_count;
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_strings') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_STRINGS] =
                    $value;
                if ($value) {
                    my $rules =
                        $grammar->[Parse::Marpa::Internal::Grammar::RULES];
                    my $rule_count = @{$rules};
                    say $trace_fh "Setting $option";
                    say $trace_fh
                        "Warning: Setting $option after $rule_count rules have been defined"
                        if $rule_count;
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_predefineds') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_PREDEFINEDS]
                    = $value;
                if ($value) {
                    my $rules =
                        $grammar->[Parse::Marpa::Internal::Grammar::RULES];
                    my $rule_count = @{$rules};
                    say $trace_fh "Setting $option";
                    say $trace_fh
                        "Warning: Setting $option after $rule_count rules have been defined"
                        if $rule_count;
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_iterations') {
		croak("trace_iterations must be set to a number >= 0")
		    unless $value =~ /^\d+$/;
                $grammar->[
                    Parse::Marpa::Internal::Grammar::TRACE_ITERATIONS]
                    = $value + 0;
                if ($value) {
                    say $trace_fh "Setting $option option to $value";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_priorities') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES]
                    = $value;
                if ($value) {
                    say $trace_fh "Setting $option";
                    say $trace_fh
                        "Warning: Setting $option after semantics were finalized"
                        if $phase
                            >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('trace_completions') {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS]
                    = $value;
                if ($value) {
                    say $trace_fh "Setting $option option";
                    $grammar->[Parse::Marpa::Internal::Grammar::TRACING] = 1;
                }
            }
            when ('location_callback') {
                croak('location callback not yet implemented');
            }
            when ('opaque') {
                croak( 'the opaque option has been removed');
            }
            when ('cycle_action') {
                say $trace_fh
                    qq{"cycle_action" option is useless after grammar is precomputed}
                    if $value
                        && $phase
                        >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
		croak("$option must be 'warn', 'quiet' or 'fatal'")
		    unless $value =~ /^(warn|quiet|fatal)$/;
                $grammar->[Parse::Marpa::Internal::Grammar::CYCLE_ACTION] =
                    $value;
            }
            when ('cycle_depth') {
		croak("cycle_depth must be set to a number > 0")
		    unless $value =~ /^\d+$/ and $value > 0;
                $grammar->[Parse::Marpa::Internal::Grammar::CYCLE_DEPTH] =
                    $value;
            }
            when ('warnings') {
                say $trace_fh
                    qq{"warnings" option is useless after grammar is precomputed}
                    if $value
                        && $phase
                        >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] =
                    $value;
            }
            when ('online') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::ONLINE] = $value;
            }
            when ('code_lines') {
                $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] =
                    $value;
            }
            when ('allow_raw_source') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::RULES;
                $grammar->[Parse::Marpa::Internal::Grammar::ALLOW_RAW_SOURCE]
                    = $value;
            }
            when ('max_parses') {
                $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES] =
                    $value;
            }
            when ('version') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::VERSION] = $value;
            }
            when ('semantics') {
                croak(
                    "$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::SEMANTICS] =
                    $value;
            }
            when ('lex_preamble') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::LEX_PREAMBLE] =
                    $value;
            }
            when ('preamble') {
                croak( "$option option not allowed in ",
                    Parse::Marpa::Internal::Phase::description($phase) )
                    if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE] =
                    $value;
            }
            default {
                croak("$_ is not an available Marpa option");
            }
        }
    }

    return $grammar;
}

=begin Implementation:

In order to automatically ELIMINATE inaccessible and unproductive
productions from a grammar, you have to first eliminate the
unproductive productions, THEN the inaccessible ones.  I don't do
this in the below.

The reason is my purposes are primarily diagnostic.  The difference
shows in the case of an unproductive start symbol.  Following the
correct procedure for automatically cleaning the grammar, I would
have to regard the start symbol and its productions as eliminated
and therefore go on to report every other production and symbol as
inaccessible.  Almost certainly all these inaccessiblity reports,
while theoretically correct, are irrelevant, since the user will
probably respond by making the start symbol productive, and the
extra "information" would only get in the way.

The downside is that in a few uncommon cases, a user relying entirely
on the Marpa warnings to clean up his grammar will have to go through
more than a single pass of the diagnostics.  I think even those
users will prefer less cluttered diagnostics, and I'm sure most
users will.

=end Implementation:

=cut

sub Parse::Marpa::Grammar::precompute {
    my $grammar = shift;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if ( $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED ) {
        croak(
            "Attempt to precompute grammar in inappropriate state\nAttempt to precompute ",
            Parse::Marpa::Internal::Phase::description($phase)
        );
    }

    nulling($grammar);
    nullable($grammar) or return $grammar;
    productive($grammar);

    my $start = $grammar->[Parse::Marpa::Internal::Grammar::START];
    croak('No start symbol specified') unless defined $start;

    set_start( $grammar, $start ) or return $grammar;

    accessible($grammar);
    if ( $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] ) {
        setup_academic_grammar($grammar);
    }
    else {
        rewrite_as_CHAF($grammar);
	detect_cycle($grammar);
    }
    create_NFA($grammar);
    create_QDFA($grammar);
    if ( $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] ) {
        my $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        for my $symbol (
            @{ Parse::Marpa::Grammar::inaccessible_symbols($grammar) } )
        {
            say $trace_fh "Inaccessible symbol: $symbol";
        }
        for my $symbol (
            @{ Parse::Marpa::Grammar::unproductive_symbols($grammar) } )
        {
            say $trace_fh "Unproductive symbol: $symbol";
        }
    }

    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::PRECOMPUTED;
    $grammar;
}

sub Parse::Marpa::Grammar::show_problems {
    my $grammar = shift;

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        my $problem_count = scalar @{$problems};
        return
            "Grammar has $problem_count problems:\n"
            . (join "\n", @{$problems}) . "\n";
    }
    return "Grammar has no problems\n";
}

# Deep Copy Grammar
#
# Note: copying strengthens weak refs
sub Parse::Marpa::Grammar::compile {
    my $grammar = shift;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    if (   $phase > Parse::Marpa::Internal::Phase::COMPILED
        or $phase < Parse::Marpa::Internal::Phase::RULES )
    {
        croak(
            "Attempt to compile grammar in inappropriate state\nAttempt to compile ",
            Parse::Marpa::Internal::Phase::description($phase)
        );
    }

    if ( $phase == Parse::Marpa::Internal::Phase::RULES ) {
        Parse::Marpa::Grammar::precompute($grammar);
    }

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::Grammar::show_problems($grammar),
            "Attempt to compile grammar with fatal problems\n",
            'Marpa cannot proceed'
        );
    }

    my $d = Data::Dumper->new( [$grammar], ['grammar'] );
    $d->Purity(1);
    $d->Indent(0);

    # returns a ref -- dumps can be long
    return \( $d->Dump() );
}

# First arg is compiled grammar
# Second arg (optional) is trace file handle, either saved and restored
# If not trace file handle supplied, it reverts to the default, STDERR
#
# Returns the decompiled grammar
sub Parse::Marpa::Grammar::decompile {
    my $compiled_grammar = shift;
    my $trace_fh         = shift;
    $trace_fh //= *STDERR;

    croak("Attempt to decompile undefined grammar")
        unless defined $compiled_grammar;

    my $grammar;
    {
        my @warnings;
        my @caller_return;
        local $SIG{__WARN__} = sub {
            my $warning = $_[0];
            push @warnings, $warning;
            @caller_return = caller 0;
        };
        eval ${$compiled_grammar};
        my $fatal_error = $@;
        if ( $fatal_error or @warnings ) {
            Parse::Marpa::Internal::code_problems(
                $fatal_error, \@warnings,
                'decompiling gramar',
                'decompiling gramar',
                $compiled_grammar, \@caller_return
            );
        }
    }

    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE] =
        $trace_fh;

    # Eliminate or weaken all circular references
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    while ( my ( $name, $ref ) = each %{$symbol_hash} ) {
        weaken( $symbol_hash->{$name} = $ref );
    }

    # these were weak references, but aren't used anyway, so
    # free up the memory
    for my $symbol (
        @{ $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS] } )
    {
        $symbol->[Parse::Marpa::Internal::Symbol::LHS] = undef;
        $symbol->[Parse::Marpa::Internal::Symbol::RHS] = undef;
    }
    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::COMPILED;

    return $grammar;

}

sub Parse::Marpa::show_symbol {
    my $symbol = shift;
    my $text   = q{};
    $text .= sprintf '%d: %s, lhs=[%s], rhs=[%s]',
        $symbol->[Parse::Marpa::Internal::Symbol::ID],
        $symbol->[Parse::Marpa::Internal::Symbol::NAME],
        (join ' ',
        map { $_->[Parse::Marpa::Internal::Rule::ID] }
            @{ $symbol->[Parse::Marpa::Internal::Symbol::LHS] }),
        (join ' ',
        map { $_->[Parse::Marpa::Internal::Rule::ID] }
            @{ $symbol->[Parse::Marpa::Internal::Symbol::RHS] });
    if ( not $symbol->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] ) {
        $text .= ' unproductive';
    }
    if ( not $symbol->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] ) {
        $text .= ' inaccessible';
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
        $text .= ' nullable';
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLING] ) {
        $text .= ' nulling';
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
        $text .= ' terminal';
    }
    return $text .= "\n";
}

sub Parse::Marpa::Grammar::show_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    my $text    = q{};
    for my $symbol_ref (@{$symbols}) {
        $text .= Parse::Marpa::show_symbol($symbol_ref);
    }
    return $text;
}

sub Parse::Marpa::Grammar::show_nulling_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::NULLING] }
            @{$symbols};
}

sub Parse::Marpa::Grammar::show_nullable_symbols {
    my $grammar = shift;
    my $symbols =
        $grammar->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL];
    return join q{ },
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @{$symbols};
}

sub Parse::Marpa::Grammar::show_productive_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] }
            @{$symbols};
}

sub Parse::Marpa::Grammar::show_accessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @{$symbols};
}

sub Parse::Marpa::Grammar::inaccessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    return [   sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { !$_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @{$symbols}
    ];
}

sub Parse::Marpa::Grammar::unproductive_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    return [   sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { !$_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] }
            @{$symbols}
    ];
}

sub Parse::Marpa::brief_rule {
    my $rule = shift;
    my ( $lhs, $rhs, $rule_id ) = @{$rule}[
        Parse::Marpa::Internal::Rule::LHS,
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::ID
    ];
    my $text .= $rule_id . ': '
        . $lhs->[Parse::Marpa::Internal::Symbol::NAME] . ' ->';
    if (@{$rhs}) {
        $text .= q{ }
            . (join q{ },
            map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @{$rhs});
    }
    return $text;
}

sub Parse::Marpa::brief_original_rule {
    my $rule          = shift;
    my $original_rule = $rule->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE]
        // $rule;
    return Parse::Marpa::brief_rule($original_rule);
}

sub Parse::Marpa::show_rule {
    my $rule = shift;

    my ( $rhs, $productive, $accessible, $nullable, $nulling, $useful,
        $priority, )
        = @{$rule}[
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::ACCESSIBLE,
        Parse::Marpa::Internal::Rule::NULLABLE,
        Parse::Marpa::Internal::Rule::NULLING,
        Parse::Marpa::Internal::Rule::USEFUL,
        Parse::Marpa::Internal::Rule::PRIORITY,
        ];
    my $text    = Parse::Marpa::brief_rule($rule);
    my @comment = ();

    if ( not(@{$rhs}) )      { push @comment, 'empty'; }
    if ( not $productive ) { push @comment, 'unproductive'; }
    if ( not $accessible ) { push @comment, 'inaccessible'; }
    if ($nullable)         { push @comment, 'nullable'; }
    if ($nulling)          { push @comment, 'nulling'; }
    if ( not $useful )     { push @comment, '!useful'; }
    my $priority_string_ref = Parse::Marpa::show_priority($priority);
    if ($priority_string_ref) {
        push @comment, 'priority=' . ${$priority_string_ref};
    }
    if (@comment) {
        $text .= ' ' . (join ' ', '/*', @comment, '*/' );
    }
    return $text .= "\n";
}

# For displaying priorities.
# Returns undefined if priority undefined or zero.
# Returns ref to a string showing dotted priority otherwise.
# A true second arg, means create a string even if priority is zero.
sub Parse::Marpa::show_priority {
    my $priority = shift;
    return unless defined $priority;
    my $defined_if_zero = shift;
    my ( $pri1, $pri2 ) = unpack 'NN', $priority;
    return unless $defined_if_zero or $pri1 or $pri2;
    return \( $pri1 . '.' . $pri2 );
}

sub Parse::Marpa::Grammar::show_rules {
    my $grammar = shift;
    my $rules   = $grammar->[Parse::Marpa::Internal::Grammar::RULES];
    my $text;

    for my $rule (@{$rules}) {
        $text .= Parse::Marpa::show_rule($rule);
    }
    return $text;
}

sub Parse::Marpa::show_dotted_rule {
    my $rule = shift;
    my $position = shift;

    my @names = 
	map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
	    $rule->[Parse::Marpa::Internal::Rule::LHS],
	    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] };
    splice @names, $position + 1, 0, q{.};
    splice @names, 1,             0, '::=';
    return join q{ }, @names;
}

sub Parse::Marpa::show_item {
    my $item = shift;
    my $text = q{};
    if ( not defined $item ) {
        $text .= '/* empty */';
    }
    else {
	$text .= Parse::Marpa::show_dotted_rule(
	     @{$item}[
		Parse::Marpa::Internal::LR0_item::RULE,
		Parse::Marpa::Internal::LR0_item::POSITION
	    ]
	);
    }
    return $text;
}

sub Parse::Marpa::show_NFA_state {
    my $state = shift;
    my ( $name, $item, $transition, $at_nulling, $priority ) = @{$state}[
        Parse::Marpa::Internal::NFA::NAME,
        Parse::Marpa::Internal::NFA::ITEM,
        Parse::Marpa::Internal::NFA::TRANSITION,
        Parse::Marpa::Internal::NFA::AT_NULLING,
        Parse::Marpa::Internal::NFA::PRIORITY,
    ];
    my $text = $name . ': ';
    $text .= Parse::Marpa::show_item($item) . "\n";
    my @properties = ();
    push @properties, 'at_nulling' if $at_nulling;
    my $priority_string_ref = Parse::Marpa::show_priority($priority);
    push @properties, 'priority=' . ${$priority_string_ref}
        if defined $priority_string_ref;
    $text .= join( ' ', @properties ) . "\n" if @properties;

    for my $symbol_name ( sort keys %{$transition} ) {
        my $transition_states = $transition->{$symbol_name};
        $text
            .= ' '
            . ( $symbol_name eq '' ? 'empty' : '<' . $symbol_name . '>' )
            . ' => '
            . join( ' ',
            map { $_->[Parse::Marpa::Internal::NFA::NAME] }
                @{$transition_states} )
            . "\n";
    }
    return $text;
}

sub Parse::Marpa::Grammar::show_NFA {
    my $grammar = shift;
    my $text    = '';
    my $NFA     = $grammar->[Parse::Marpa::Internal::Grammar::NFA];
    for my $state (@{$NFA}) {
        $text .= Parse::Marpa::show_NFA_state($state);
    }
    return $text;
}

sub Parse::Marpa::brief_QDFA_state {
    my $state = shift;
    my $tags  = shift;
    return 'St' . $state->[Parse::Marpa::Internal::QDFA::TAG]
        if defined $tags;
    return 'S' . $state->[Parse::Marpa::Internal::QDFA::ID];
}

sub Parse::Marpa::show_QDFA_state {
    my $state = shift;
    my $tags  = shift;

    my $text = '';
    my ( $name, $NFA_states, $transition, $predict, $priority ) = @{$state}[
        Parse::Marpa::Internal::QDFA::NAME,
        Parse::Marpa::Internal::QDFA::NFA_STATES,
        Parse::Marpa::Internal::QDFA::TRANSITION,
        Parse::Marpa::Internal::QDFA::RESET_ORIGIN,
        Parse::Marpa::Internal::QDFA::PRIORITY,
    ];

    $text .= Parse::Marpa::brief_QDFA_state( $state, $tags ) . ': ';
    $text .= 'predict; ' if $predict;
    my $priority_string_ref = Parse::Marpa::show_priority($priority);
    $text .= 'pri=' . ${$priority_string_ref} . '; '
        if defined $priority_string_ref;
    $text .= $name . "\n";
    for my $NFA_state (@{$NFA_states}) {
        my $item = $NFA_state->[Parse::Marpa::Internal::NFA::ITEM];
        $text .= Parse::Marpa::show_item($item) . "\n";
    }

    for my $symbol_name ( sort keys %{$transition} ) {
        $text .= ' <' . $symbol_name . '> => ';
        my @qdfa_labels;
        for my $to_state ( @{ $transition->{$symbol_name} } ) {
            my $to_name = $to_state->[Parse::Marpa::Internal::QDFA::NAME];
            push @qdfa_labels,
                Parse::Marpa::brief_QDFA_state( $to_state, $tags );
        }    # for my $to_state
        $text .= join '; ', sort @qdfa_labels;
        $text .= "\n";
    }

    return $text;
}

sub tag_QDFA {
    my $grammar = shift;
    my $QDFA    = $grammar->[Parse::Marpa::Internal::Grammar::QDFA];
    return if defined $QDFA->[0]->[Parse::Marpa::Internal::QDFA::TAG];
    my $tag = 0;
    for my $state (
        sort {
            $a->[Parse::Marpa::Internal::QDFA::NAME]
                cmp $b->[Parse::Marpa::Internal::QDFA::NAME]
        } @{$QDFA}
        )
    {
        $state->[Parse::Marpa::Internal::QDFA::TAG] = $tag++;
    }
    return;
}

sub Parse::Marpa::Grammar::show_QDFA {
    my $grammar = shift;
    my $tags    = shift;

    my $text = q{};
    my $QDFA = $grammar->[Parse::Marpa::Internal::Grammar::QDFA];
    my $start_states =
        $grammar->[Parse::Marpa::Internal::Grammar::START_STATES];
    $text .= 'Start States: ';
    $text .= join '; ',
        sort map { Parse::Marpa::brief_QDFA_state( $_, $tags ) }
            @{$start_states};
    $text .= "\n";

    for my $state (@{$QDFA}) {
        $text .= Parse::Marpa::show_QDFA_state( $state, $tags );
    }
    return $text;
}

sub Parse::Marpa::Grammar::show_ii_QDFA {
    my $grammar = shift;
    my $text    = '';
    my $QDFA    = $grammar->[Parse::Marpa::Internal::Grammar::QDFA];
    my $tags;
    tag_QDFA($grammar);

    for my $state (@{$QDFA}) {
        $tags->[ $state->[Parse::Marpa::Internal::QDFA::ID] ] =
            $state->[Parse::Marpa::Internal::QDFA::TAG];
    }
    my $start_states =
        $grammar->[Parse::Marpa::Internal::Grammar::START_STATES];
    $text .= 'Start States: ';
    $text .= join '; ',
        sort map { Parse::Marpa::brief_QDFA_state( $_, $tags ) }
            @{$start_states};
    $text .= "\n";
    for my $state (
        map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map  { [ $_, $_->[Parse::Marpa::Internal::QDFA::TAG] ] } @{$QDFA}
        )
    {
        $text .= Parse::Marpa::show_QDFA_state( $state, $tags );
    }
    return $text;
}

sub Parse::Marpa::Grammar::get_symbol {
    my $grammar = shift;
    my $name    = shift;
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    return defined $symbol_hash ? $symbol_hash->{$name} : undef;
}

sub add_terminal {
    my $grammar = shift;
    my $name    = shift;
    my $options = shift;
    my ( $regex, $prefix, $suffix );
    my $action;
    my $user_priority = 0;

    while ( my ( $key, $value ) = each %{$options} ) {
        given ($key) {
            when ('priority') { $user_priority = $value; }
            when ('action')   { $action        = $value; }
            when ('prefix')   { $prefix        = $value; }
            when ('suffix')   { $suffix        = $value; }
            when ('regex')    { $regex         = $value; }
            default {
                croak(
                    "Attempt to add terminal named $name with unknown option $key"
                );
            }
        }
    }

    my ( $symbol_hash, $symbols, $default_null_value ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    # I allow redefinition of a LHS symbol as a terminal
    # I need to test that this works, or disallow it
    #
    # 11 August 2008 -- I'm pretty sure I have tested this,
    # but sometime should test it again to make sure
    # before removing this comment

    my $symbol = $symbol_hash->{$name};
    if ( defined $symbol ) {

        if ( $symbol->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
            croak("Attempt to add terminal twice: $name");
        }

        @{$symbol}[
            Parse::Marpa::Internal::Symbol::PRODUCTIVE,
            Parse::Marpa::Internal::Symbol::NULLING,
            Parse::Marpa::Internal::Symbol::REGEX,
            Parse::Marpa::Internal::Symbol::PREFIX,
            Parse::Marpa::Internal::Symbol::SUFFIX,
            Parse::Marpa::Internal::Symbol::ACTION,
            Parse::Marpa::Internal::Symbol::TERMINAL,
            Parse::Marpa::Internal::Symbol::PRIORITY,
            ]
            = (
            1, 0, $regex, $prefix, $suffix, $action, 1,
            (pack 'NN', $user_priority, 0 )
            );

        return;
    }

    my $symbol_count = @{$symbols};
    my $new_symbol   = [];
    @{$new_symbol}[
        Parse::Marpa::Internal::Symbol::ID,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::REGEX,
        Parse::Marpa::Internal::Symbol::ACTION,
        Parse::Marpa::Internal::Symbol::TERMINAL,
        Parse::Marpa::Internal::Symbol::PRIORITY,
        ]
        = (
        $symbol_count, $name, [], [], 0, 1, 0, $regex, $action, 1,
        (pack 'NN', $user_priority, 0 )
        );

    push @{$symbols}, $new_symbol;
    return weaken( $symbol_hash->{$name} = $new_symbol );
}

sub assign_symbol {
    my $grammar = shift;
    my $name    = shift;
    my ( $symbol_hash, $symbols, $default_null_value, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    my $symbol_count = @{$symbols};
    my $symbol       = $symbol_hash->{$name};
    if ( not defined $symbol ) {
        @{$symbol}[
            Parse::Marpa::Internal::Symbol::ID,
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::LHS,
            Parse::Marpa::Internal::Symbol::RHS,
            ]
            = ( $symbol_count, $name, [], [] );
        push @{$symbols}, $symbol;
        weaken( $symbol_hash->{$name} = $symbol );
    }
    $symbol;
}

sub assign_user_symbol {
    my $self = shift;
    my $name = shift;
    croak("Symbol name $name ends in ']': that's not allowed")
        if $name =~ /_$/;
    assign_symbol( $self, $name );
}

sub add_user_rule {
    my $grammar       = shift;
    my $lhs_name      = shift;
    my $rhs_names     = shift;
    my $action        = shift;
    my $user_priority = shift;

    my ($rule_hash) = @{$grammar}[Parse::Marpa::Internal::Grammar::RULE_HASH];

    my $lhs_symbol = assign_user_symbol( $grammar, $lhs_name );
    $rhs_names //= [];
    my $rhs_symbols =
        [ map { assign_user_symbol( $grammar, $_ ); } @{$rhs_names} ];

    # Don't allow the user to duplicate a rule
    my $rule_key = join ',',
        map { $_->[Parse::Marpa::Internal::Symbol::ID] }
            ( $lhs_symbol, @{$rhs_symbols} );
    croak( 'Duplicate rule: ', $lhs_name, ' -> ', (join ' ', @{$rhs_names}) )
        if exists $rule_hash->{$rule_key};

    $rule_hash->{$rule_key} = 1;

    $user_priority //= 0;
    my $max_priority = 1_000_000;
    if ( $user_priority > $max_priority ) {
        croak(
            "Rule priority ($user_priority) greater than maximum ($max_priority)"
        );
    }
    my $min_priority = -1_000_000;
    if ( $user_priority < $min_priority ) {
        croak(
            "Rule priority ($user_priority) less than minimum ($min_priority)"
        );
    }

    return add_rule( $grammar, $lhs_symbol, $rhs_symbols, $action,
        (pack 'NN', $user_priority, 0 ) );
}

sub add_rule {
    my $grammar  = shift;
    my $lhs      = shift;
    my $rhs      = shift;
    my $action   = shift;
    my $priority = shift;

    my ( $rules, $package, $trace_rules, $trace_fh, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::NAME,
        Parse::Marpa::Internal::Grammar::TRACE_RULES,
        Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE,
    ];

    my $rule_count = @{$rules};
    my $new_rule   = [];
    my $nulling    = @{$rhs} ? undef : 1;
    $priority //= pack 'NN', 0, 0;

    @{$new_rule}[
        Parse::Marpa::Internal::Rule::ID,
        Parse::Marpa::Internal::Rule::NAME,
        Parse::Marpa::Internal::Rule::LHS,
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::NULLABLE,
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::NULLING,
        Parse::Marpa::Internal::Rule::ACTION,
        Parse::Marpa::Internal::Rule::PRIORITY,
        ]
        = (
        $rule_count, "rule $rule_count", $lhs,
        $rhs,        $nulling,           $nulling,
        $nulling,    $action,            $priority,
        );

    push @{$rules}, $new_rule;
    {
        my $lhs_rules = $lhs->[Parse::Marpa::Internal::Symbol::LHS];
        weaken( $lhs_rules->[ scalar @{$lhs_rules} ] = $new_rule );
    }
    if ($nulling) {
        @{$lhs}[
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::PRODUCTIVE
            ]
            = ( 1, 1 );
    }
    else {
        my $last_symbol = [];
        SYMBOL: for my $symbol ( sort @{$rhs} ) {
            next SYMBOL if $symbol == $last_symbol;
            my $rhs_rules = $symbol->[Parse::Marpa::Internal::Symbol::RHS];
            weaken( $rhs_rules->[ scalar @{$rhs_rules} ] = $new_rule );
            $last_symbol = $symbol;
        }
    }
    if ($trace_rules) {
        print $trace_fh 'Added rule #', $#{$rules}, ': ',
            $lhs->[Parse::Marpa::Internal::Symbol::NAME], ' -> ',
            join( ' ',
            map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @{$rhs} ),
            "\n";
    }
    return $new_rule;
}

# add one or more rules
sub add_user_rules {
    my $grammar = shift;
    my $rules   = shift;

    RULE: for my $rule (@{$rules}) {

        given ( ref $rule ) {
            when ('ARRAY') {
                my $arg_count = @{$rule};

                if ( $arg_count > 4 or $arg_count < 1 ) {
                    croak(
                        "Rule has $arg_count arguments: "
                            . join( ', ',
                            map { defined $_ ? $_ : 'undef' } @{$rule} )
                            . "\n"
                            . 'Rule must have from 1 to 3 arguments'
                    );
                }
                my ( $lhs, $rhs, $action, $user_priority ) = @{$rule};
                add_user_rule( $grammar, $lhs, $rhs, $action,
                    $user_priority );

            }
            when ('HASH') {
                add_rules_from_hash( $grammar, $rule );
            }
            default {
                croak( 'Invalid rule reftype ', ( $_ ? $_ : 'undefined' ) );
            }
        }

    }    # RULE

    return;

}

sub add_rules_from_hash {
    my $grammar = shift;
    my $options = shift;

    my ( $lhs_name, $rhs_names, $action );
    my ( $min,      $max,       $separator_name );
    my $proper_separation = 0;
    my $keep_separation   = 0;
    my $left_associative  = 1;
    my $user_priority     = 0;

    while ( my ( $option, $value ) = each %{$options} ) {
        given ($option) {
            when ('rhs')               { $rhs_names         = $value }
            when ('lhs')               { $lhs_name          = $value }
            when ('action')            { $action            = $value }
            when ('min')               { $min               = $value }
            when ('separator')         { $separator_name    = $value }
            when ('proper_separation') { $proper_separation = $value }
            when ('left_associative')  { $left_associative  = $value }
            when ('right_associative') { $left_associative  = !$value }
            when ('priority')          { $user_priority     = $value }
            default { croak("Unknown option in counted rule: $option") };
        }
    }

    croak('Only left associative sequences available')
        unless $left_associative;
    given ($min) {
	when (undef) {;}
	when ([0, 1]) {;}
	default {
	    croak('If min is defined for a rule, it must be 0 or 1')
	}
    }

    if ( scalar @{$rhs_names} == 0 or not defined $min) {

        if (defined $separator_name ) {
            croak('separator defined for rule without repetitions');
	}

	# This is an ordinary, non-counted rule,
	# which we'll take care of first as a special case
	my $ordinary_rule =
	    add_user_rule( $grammar, $lhs_name, $rhs_names, $action,
		$user_priority );

        return;

    }  # not defined $min

    # At this point we know that min must be 0 or 1
    # and that there is at least one symbol on the rhs

    # nulling rule is special case
    if ( $min == 0 ) {
        my $rule_action;
        given ($action) {
            when (undef) { $rule_action = undef }
            default {
                $rule_action = q{ @_ = (); } . $action;
            }
        }
        add_user_rule( $grammar, $lhs_name, [], $rule_action,
            $user_priority );
        $min = 1;
    }

    croak('Only one rhs symbol allowed for counted rule')
        if scalar @{$rhs_names} != 1;

    # create the rhs symbol
    my $rhs_name = pop @{$rhs_names};
    my $rhs = assign_user_symbol( $grammar, $rhs_name );
    $rhs->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;

    # create the separator symbol, if we're using one
    my $separator;
    if ( defined $separator_name ) {
        $separator = assign_user_symbol( $grammar, $separator_name );
        $separator->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;
    }

    # create the sequence symbol
    my $sequence_name = $rhs_name . "[Seq:$min-*]";
    if ( defined $separator_name ) {
        my $punctuation_free_separator_name = $separator_name;
        $punctuation_free_separator_name =~ s/[^[:alnum:]]/_/g;
        $sequence_name .= '[Sep:' . $punctuation_free_separator_name . ']';
    }
    my $unique_name_piece = sprintf '[x%x]',
        scalar @{ $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS] };
    $sequence_name .= $unique_name_piece;
    my $sequence = assign_symbol( $grammar, $sequence_name );

    my $lhs = assign_user_symbol( $grammar, $lhs_name );

    # Don't allow the user to duplicate a rule
    # I'm pretty general here -- I consider a sequence rule a duplicate if rhs, lhs
    # and separator are the same.  I may want to get more fancy, but save that
    # for later.
    {
        my $rule_hash =
            $grammar->[Parse::Marpa::Internal::Grammar::RULE_HASH];
        my @key_rhs =
            defined $separator ? ( $rhs, $separator, $rhs ) : ($rhs);
        my $rule_key = join ',',
            map { $_->[Parse::Marpa::Internal::Symbol::ID] }
                ( $lhs, @key_rhs );
        croak( 'Duplicate rule: ',
            $lhs_name, ' -> ', (join ',', @{$rhs_names}) )
            if exists $rule_hash->{$rule_key};
        $rule_hash->{$rule_key} = 1;
    }

    # The following rules make evaluations opaque
    $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE] = 1;

    my $rule_action;
    given ($action) {
        when (undef) { $rule_action = undef; }
        default {
            if ($left_associative) {

                # more efficient way to do this?
                $rule_action = q{
                    HEAD: for (;;) {
                        my $head = shift @_;
                        last HEAD unless scalar @{$head};
                        unshift(@_, @{$head});
                    }
                }
            }
            else {
		croak('Only left associative sequences available')
            }
            $rule_action .= $action;
        }
    }
    add_rule( $grammar, $lhs, [$sequence], $rule_action,
        (pack 'NN', $user_priority, 0 ) );
    if ( defined $separator and not $proper_separation ) {
        unless ($keep_separation) {
            $rule_action = q{ pop @_; } . ( $rule_action // q{} );
        }
        add_rule( $grammar, $lhs, [ $sequence, $separator, ],
            $rule_action, (pack 'NN', $user_priority, 0 ) );
    }

    my @separated_rhs = ($rhs);
    push @separated_rhs, $separator if defined $separator;

    # minimal sequence rule
    my $counted_rhs = [ (@separated_rhs) x ( $min - 1 ), $rhs ];

    if ($left_associative) {
        if ( defined $separator and not $keep_separation ) {
            $rule_action = q{
                [
                    [],
                    @_[
                        grep { !($_ % 2) } (0 .. $#_)
                    ]
                ]
            }
        }
        else {
            $rule_action = q{
                unshift(@_, []);
                \@_
            }
        }
    }
    else {
	croak('Only left associative sequences available')
    }

    add_rule( $grammar, $sequence, $counted_rhs, $rule_action,
        (pack 'NN', $user_priority, 0 ) );

    # iterating sequence rule
    $rule_action = ( defined $separator and not $keep_separation )
        ? q{
            [
                @_[
                   grep { !($_ % 2) } (0 .. $#_)
                ],
            ]
        }
        : q{
            \@_
        };
    my @iterating_rhs = ( @separated_rhs, $sequence );
    if ($left_associative) {
        @iterating_rhs = reverse @iterating_rhs;
    }
    add_rule( $grammar, $sequence, ( \@iterating_rhs ),
        $rule_action, (pack 'NN', $user_priority, 0 ) );

     return;

}    # sub add_rules_from_hash

sub add_user_terminals {
    my $grammar   = shift;
    my $terminals = shift;

    TERMINAL: for my $terminal (@{$terminals}) {
        my $arg_count = @{$terminal};
        if ( $arg_count > 2 or $arg_count < 1 ) {
            croak('terminal must have from 1 or 2 arguments');
        }
        my ( $lhs_name, $options ) = @{$terminal};
        add_user_terminal( $grammar, $lhs_name, $options );
    }
    return;
}

sub add_user_terminal {
    my $grammar = shift;
    my $name    = shift;
    my $options = shift;

    croak("Symbol name $name ends in ']': that's not allowed")
        if $name =~ /_$/;
    add_terminal( $grammar, $name, $options );
    return;
}

sub set_start {
    my $grammar    = shift;
    my $start_name = shift;
    my $success    = 1;

    # my $trace_fh =
    # $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    my $start = $symbol_hash->{$start_name};

    if ( not defined $start ) {
        croak( 'Start symbol: ' . $start_name . ' not defined' )
    }

    my ( $lhs, $rhs, $terminal, $productive ) = @{$start}[
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::TERMINAL,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
    ];

    if ( not scalar @{$lhs} and not $terminal ) {
        my $problem =
            'Start symbol ' . $start_name . ' not on LHS of any rule';
        push @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem;
        $success = 0;
    }

    if ( not $productive ) {
        my $problem = 'Unproductive start symbol: ' . $start_name;
        push @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem;
        $success = 0;
    }

    $grammar->[Parse::Marpa::Internal::Grammar::START] = $start;

    $success;
}

# return list of rules reachable from the start symbol;
sub accessible {
    my $grammar = shift;
    my $start   = $grammar->[Parse::Marpa::Internal::Grammar::START];

    $start->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] = 1;
    my $symbol_work_set = [$start];
    my $rule_work_set   = [];

    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS: while ( my $work_symbol = shift @{$symbol_work_set} ) {
            my $rules_produced =
                $work_symbol->[Parse::Marpa::Internal::Symbol::LHS];
            PRODUCED_RULE: for my $rule (@{$rules_produced}) {

                next PRODUCED_RULE
                    if
                    defined $rule->[Parse::Marpa::Internal::Rule::ACCESSIBLE];

                $rule->[Parse::Marpa::Internal::Rule::ACCESSIBLE] = 1;
                $work_to_do++;
                push @{$rule_work_set}, $rule;

            }
        }    # SYMBOL_PASS

        RULE: while ( my $work_rule = shift @{$rule_work_set} ) {
            my $rhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::RHS];

            RHS: for my $symbol (@{$rhs_symbol}) {

                next RHS
                    if defined
                        $symbol->[Parse::Marpa::Internal::Symbol::ACCESSIBLE];
                $symbol->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] = 1;
                $work_to_do++;

                push @{$symbol_work_set}, $symbol;
            }

        }    # RULE

    }    # work_to_do loop

}

sub productive {
    my $grammar = shift;

    my ( $rules, $symbols ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS
    ];

    # If a symbol's nullability could not be determined, it was unproductive.
    # All nullable symbols are productive.
    for my $symbol (@{$symbols}) {
        if ( not defined $_->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 0;
        }
        if ( $_->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 1;
        }
    }

    # If a rule's nullability could not be determined, it was unproductive.
    # All nullable rules are productive.
    for my $rule (@{$rules}) {
        if ( not defined $rule->[Parse::Marpa::Internal::Rule::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 0;
        }
        if ( $rule->[Parse::Marpa::Internal::Rule::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 1;
        }
    }

    my $symbol_work_set = [];
    $#{$symbol_work_set} = $#{$symbols};
    my $rule_work_set = [];
    $#{$rule_work_set} = $#{$rules};

    for my $symbol_id (
        grep {
            defined $symbols->[$_]
                ->[Parse::Marpa::Internal::Symbol::PRODUCTIVE]
        } ( 0 .. $#{$symbols} )
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }
    for my $rule_id (
        grep {
            defined $rules->[$_]->[Parse::Marpa::Internal::Rule::PRODUCTIVE]
        } ( 0 .. $#{$rules} )
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }
    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#{$symbol_work_set} ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;

            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];
            PRODUCING_RULE: for my $rule (@{$rules_producing}) {

                # no work to do -- this rule already has productive status marked
                next PRODUCING_RULE
                    if
                    defined $rule->[Parse::Marpa::Internal::Rule::PRODUCTIVE];

                # assume productive until we hit an unmarked or unproductive symbol
                my $rule_productive = 1;

                # are all symbols on the RHS of this rule bottom marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $productive = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::PRODUCTIVE];

                    # unmarked symbol, change the assumption for rule to undef,
                    # but keep scanning for unproductive
                    # symbol, which will override everything else
                    if ( not defined $productive ) {
                        $rule_productive = undef;
                        next RHS_SYMBOL;
                    }

                    # any unproductive RHS symbol means the rule is unproductive
                    if ( $productive == 0 ) {
                        $rule_productive = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule productive or unproductive, mark the rule
                if ( defined $rule_productive ) {
                    $rule->[Parse::Marpa::Internal::Rule::PRODUCTIVE] =
                        $rule_productive;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#{$rule_work_set} ) )
        {
            my $work_rule = $rules->[$rule_id];
            $rule_work_set->[$rule_id] = 0;
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already has productive status marked
            next RULE
                if defined
                    $lhs_symbol->[Parse::Marpa::Internal::Symbol::PRODUCTIVE];

            # assume unproductive until we hit an unmarked or non-nullable symbol
            my $symbol_productive = 0;

            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $productive =
                    $rule->[Parse::Marpa::Internal::Rule::PRODUCTIVE];

                # unmarked symbol, change the assumption for rule to undef, but keep scanning for nullable
                # rule, which will override everything else
                if ( not defined $productive ) {
                    $symbol_productive = undef;
                    next LHS_RULE;
                }

                # any productive rule means the LHS is productive
                if ( $productive == 1 ) {
                    $symbol_productive = 1;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol productive or unproductive, mark the symbol
            if ( defined $symbol_productive ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] =
                    $symbol_productive;
                $work_to_do++;
                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

    }    # work_to_do loop

}

sub nulling {
    my $grammar = shift;

    my ( $rules, $symbols ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
    ];

    my $symbol_work_set = [];
    $#{$symbol_work_set} = $#{$symbols};
    my $rule_work_set = [];
    $#{$rule_work_set} = $#{$rules};

    for my $rule_id (
        map  { $_->[Parse::Marpa::Internal::Rule::ID] }
        grep { $_->[Parse::Marpa::Internal::Rule::NULLING] } @{$rules}
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }

    for my $symbol_id (
        map  { $_->[Parse::Marpa::Internal::Symbol::ID] }
        grep { $_->[Parse::Marpa::Internal::Symbol::NULLING] } @{$symbols}
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }

    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#{$rule_work_set} ) )
        {
            my $work_rule = $rules->[$rule_id];
            $rule_work_set->[$rule_id] = 0;
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already is marked one way or the other
            next RULE
                if defined
                    $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLING];

            # assume nulling until we hit an unmarked or non-nulling symbol
            my $symbol_nulling = 1;

            # make sure that all rules for this lhs are nulling
            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $nulling = $rule->[Parse::Marpa::Internal::Rule::NULLING];

                # unmarked rule, change the assumption for the symbol to undef,
                # but keep scanning for rule marked non-nulling,
                # which will override everything else
                if ( not defined $nulling ) {
                    $symbol_nulling = undef;
                    next LHS_RULE;
                }

                # any non-nulling rule means the LHS is not nulling
                if ( $nulling == 0 ) {
                    $symbol_nulling = 0;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol nulling or non-nulling
            #  mark the symbol
            if ( defined $symbol_nulling ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLING] =
                    $symbol_nulling;
                $work_to_do++;

                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#{$symbol_work_set} ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;

            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];
            PRODUCING_RULE: for my $rule (@{$rules_producing}) {

                # no work to do -- this rule already has nulling marked
                next PRODUCING_RULE
                    if defined $rule->[Parse::Marpa::Internal::Rule::NULLING];

                # assume nulling until we hit an unmarked or non-nulling symbol
                my $rule_nulling = 1;

                # are all symbols on the RHS of this rule marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $nulling = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::NULLING];

                    # unmarked rule, change the assumption for rule to undef,
                    # but keep scanning for non-nulling
                    # rule, which will override everything else
                    if ( not defined $nulling ) {
                        $rule_nulling = undef;
                        next RHS_SYMBOL;
                    }

                    # any non-nulling RHS symbol means the rule is non-nulling
                    if ( $nulling == 0 ) {
                        $rule_nulling = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule nulling or non-nulling, mark the rule
                if ( defined $rule_nulling ) {
                    $rule->[Parse::Marpa::Internal::Rule::NULLING] =
                        $rule_nulling;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

    }    # work_to_do loop

}

# returns undef if there was a problem
sub nullable {
    my $grammar = shift;
    my ( $rules, $symbols, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    }

    # boolean to track if current pass has changed anything
    my $work_to_do = 1;

    my $symbol_work_set = [];
    $#{$symbol_work_set} = @{$symbols};
    my $rule_work_set = [];
    $#{$rule_work_set} = @{$rules};

    for my $symbol_id (
        map { $_->[Parse::Marpa::Internal::Symbol::ID] }
        grep {
                   $_->[Parse::Marpa::Internal::Symbol::NULLABLE]
                or $_->[Parse::Marpa::Internal::Symbol::NULLING]
        } @{$symbols}
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }
    for my $rule_id (
        map  { $_->[Parse::Marpa::Internal::Rule::ID] }
        grep { defined $_->[Parse::Marpa::Internal::Rule::NULLABLE] } @{$rules}
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#{$symbol_work_set} ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;
            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];

            PRODUCING_RULE: for my $rule (@{$rules_producing}) {

                # assume nullable until we hit an unmarked or non-nullable symbol
                my $rule_nullable = 1;

                # no work to do -- this rule already has nullability marked
                next PRODUCING_RULE
                    if
                    defined $rule->[Parse::Marpa::Internal::Rule::NULLABLE];

                # are all symbols on the RHS of this rule bottom marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $nullable = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::NULLABLE];

                    # unmarked symbol, change the assumption for rule to undef, but keep scanning for non-nullable
                    # symbol, which will override everything else
                    if ( not defined $nullable ) {
                        $rule_nullable = undef;
                        next RHS_SYMBOL;
                    }

                    # any non-nullable RHS symbol means the rule is not nullable
                    if ( $nullable == 0 ) {
                        $rule_nullable = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule nullable or not, so mark the rule
                if ( defined $rule_nullable ) {
                    $rule->[Parse::Marpa::Internal::Rule::NULLABLE] =
                        $rule_nullable;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#{$rule_work_set} ) )
        {
            my $work_rule  = $rules->[$rule_id];
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already has nullability marked
            next RULE
                if defined
                    $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLABLE];

            # assume non-nullable until we hit an unmarked or non-nullable symbol
            my $symbol_nullable = 0;

            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $nullable =
                    $rule->[Parse::Marpa::Internal::Rule::NULLABLE];

                # unmarked symbol, change the assumption for rule to undef,
                # but keep scanning for nullable
                # rule, which will override everything else
                if ( not defined $nullable ) {
                    $symbol_nullable = undef;
                    next LHS_RULE;
                }

                # any nullable rule means the LHS is nullable
                if ( $nullable == 1 ) {
                    $symbol_nullable = 1;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol nullable or not, mark the symbol
            if ( defined $symbol_nullable ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLABLE] =
                    $symbol_nullable;
                $work_to_do++;
                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

    }    # work_to_do loop

    my $counted_nullable_count;
    for my $symbol (@{$symbols}) {
        my ( $name, $nullable, $counted, ) = @{$symbol}[
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::COUNTED,
        ];
        if ( $nullable and $counted ) {
            my $problem = "Nullable symbol $name is on rhs of counted rule";
            push @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
                $problem;
            $counted_nullable_count++;
        }
    }
    if ($counted_nullable_count) {
        my $problem =
            'Counted nullables confuse Marpa -- please rewrite the grammar';
        push @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem;
        return;
    }

    return 1;

}

# This assumes the grammar has been rewritten into CHAF form.
sub detect_cycle {
    my $grammar = shift;
    my ( $rules, $symbols, $cycle_action, $trace_fh) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::CYCLE_ACTION,
	Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE,
    ];

    my $cycle_is_fatal = 1;
    my $warn_on_cycle = 1;
    given ($cycle_action) {
	when ('warn') { $cycle_is_fatal = 0; }
	when ('quiet') {
	    $cycle_is_fatal = 0;
	    $warn_on_cycle = 0;
	}
    }

    my @unit_derivation; # for the unit derivation matrix
    my @new_unit_derivations; # a list of new unit derivations
    my @unit_rules; # a list of the unit rules

    # initialize the unit derivations from the rules
    RULE: for my $rule (@{$rules}) {
        next RULE if not $rule->[Parse::Marpa::Internal::Rule::USEFUL];
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];
        my $non_nullable_symbol;

	# Only one empty rule is allowed in a CHAF grammar -- a nulling
	# start rule -- this takes care of that exception.
	next RULE unless scalar @{$rhs};

        for my $rhs_symbol (@{$rhs}) {
            if ( not $rhs_symbol->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {

                # if we have two non-nullables on the RHS in this rule,
                # it can never amount to a unit rule and we can ignore it
                next RULE if defined $non_nullable_symbol;

                $non_nullable_symbol = $rhs_symbol;
            }
        }    # for $rhs_symbol

	# Above we've eliminated all rules with two or more non-nullables
	# on the RHS.  So here we have a rule with at most one non-nullable
	# on the RHS.

	next RULE unless defined $non_nullable_symbol;

        my $start_id =
            $rule->[Parse::Marpa::Internal::Rule::LHS]
            ->[Parse::Marpa::Internal::Symbol::ID];
	my $derived_id = $non_nullable_symbol->[Parse::Marpa::Internal::Symbol::ID];

	# Keep track of our unit rules
	push(@unit_rules, [ $rule, $start_id, $derived_id ]);

	$unit_derivation[$start_id][$derived_id] = 1;
	push(@new_unit_derivations, [ $start_id, $derived_id ]);

    }


    # Now find the transitive closure of the unit derivation matrix
    CLOSURE_LOOP: while (my $new_unit_derivation = shift @new_unit_derivations) {

	my ($start_id, $derived_id) = @{$new_unit_derivation};
	ID: for my $id (0 .. $#{$symbols}) {
	    # does the derived symbol derive this id?
	    # if not, no new derivation, and continue looping
	    next ID if not $unit_derivation[$derived_id][$id];

	    # also, if we've already recorded this unit derivation,
	    # skip it
	    next ID if $unit_derivation[$start_id][$id];

	    $unit_derivation[$start_id][$id] = 1;
	    push(@new_unit_derivations, [$start_id, $id]);
	}

    }

    my $cycle_count = 0;

    # produce a list of the rules which cycle
    RULE: while (my $unit_rule_data = pop @unit_rules) {

	my ($rule, $start_symbol_id, $derived_symbol_id) = @{$unit_rule_data};

        if (
	    $start_symbol_id == $derived_symbol_id
	    || $unit_derivation[$derived_symbol_id][$start_symbol_id]
	)
	{
	    $cycle_count++;
	    $rule->[Parse::Marpa::Internal::Rule::CYCLE] = 1;

	    my $warning_rule;

	    my $original_rule = $rule->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE];
	    if (defined $original_rule)
	    {
		if (not $original_rule->[Parse::Marpa::Internal::Rule::CYCLE]) {
		   $original_rule->[Parse::Marpa::Internal::Rule::CYCLE] = 1;
		   $warning_rule = $original_rule;
		}
	    } else {
		# always warn if there's no original rule
	        $warning_rule = $rule;
	    }

	    print {$trace_fh}
		    "Cycle found involving rule: ",
		    Parse::Marpa::show_rule($warning_rule)
	        if $warn_on_cycle and defined $warning_rule;
	}
    }

    croak( 'Cycle in grammar, fatal error' )
       if $cycle_count and $cycle_is_fatal;

}    # sub detect_cycle

sub create_NFA {
    my $grammar = shift;
    my ( $rules, $symbols, $symbol_hash, $start, $academic ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::START,
        Parse::Marpa::Internal::Grammar::ACADEMIC
    ];

    $grammar->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL] =
        [ grep { $_->[Parse::Marpa::Internal::Symbol::NULLABLE] } @{$symbols} ];

    my $NFA = [];
    $grammar->[Parse::Marpa::Internal::Grammar::NFA] = $NFA;

    my $state_id = 0;
    my @NFA_by_item;

    # create S0
    my $s0 = [];
    @{$s0}[
        Parse::Marpa::Internal::NFA::ID,
        Parse::Marpa::Internal::NFA::NAME,
        Parse::Marpa::Internal::NFA::TRANSITION
        ]
        = ( $state_id++, 'S0', {} );
    push @{$NFA}, $s0;

    # create the other states
    RULE: for my $rule (@{$rules}) {
        my ( $rule_id, $rhs, $useful ) = @{$rule}[
            Parse::Marpa::Internal::Rule::ID,
            Parse::Marpa::Internal::Rule::RHS,
            Parse::Marpa::Internal::Rule::USEFUL
        ];
        next RULE unless $academic or $useful;
        for my $position ( 0 .. scalar @{$rhs} ) {
            my $new_state = [];
            @{$new_state}[
                Parse::Marpa::Internal::NFA::ID,
                Parse::Marpa::Internal::NFA::NAME,
                Parse::Marpa::Internal::NFA::ITEM,
                Parse::Marpa::Internal::NFA::TRANSITION
                ]
                = ( $state_id, 'S' . $state_id, [ $rule, $position ], {} );
            $state_id++;
            push @{$NFA}, $new_state;
            $NFA_by_item[$rule_id][$position] = $new_state;
        }    # position
    }    # rule

    # now add the transitions
    STATE: for my $state (@{$NFA}) {
        my ( $id, $name, $item, $transition ) = @{$state};

        # First, deal with transitions from state 0.
        # S0 is the state with no LR(0) item
        if ( not defined $item ) {

            # start rules are rules with the start symbol
            # or with the start alias on the LHS.
            my @start_rules =
                @{ $start->[Parse::Marpa::Internal::Symbol::LHS] };
            my $start_alias =
                $start->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
            if ( defined $start_alias ) {
                push @start_rules,
                    @{  $start_alias->[Parse::Marpa::Internal::Symbol::LHS] };
            }

            # From S0, add an empty transition to the every NFA state
            # corresponding to a start rule with the dot at the beginning
            # of the RHS.
            RULE: for my $start_rule (@start_rules) {
                my ( $start_rule_id, $useful ) = @{$start_rule}[
                    Parse::Marpa::Internal::Rule::ID,
                    Parse::Marpa::Internal::Rule::USEFUL
                ];
                next RULE unless $useful;
                push @{ $transition->{ q{} } },
                    $NFA_by_item[$start_rule_id][0];
            }
            next STATE;
        }

        # transitions from states other than state 0:

        my ( $rule, $position ) = @{$item}[
            Parse::Marpa::Internal::LR0_item::RULE,
            Parse::Marpa::Internal::LR0_item::POSITION
        ];
        my $rule_id = $rule->[Parse::Marpa::Internal::Rule::ID];
        my $next_symbol =
            $rule->[Parse::Marpa::Internal::Rule::RHS]->[$position];

        # no transitions if position is after the end of the RHS
        if ( not defined $next_symbol ) {
            $state->[Parse::Marpa::Internal::NFA::COMPLETE] = 1;
            $state->[Parse::Marpa::Internal::NFA::PRIORITY] =
                $rule->[Parse::Marpa::Internal::Rule::PRIORITY];
            next STATE;
        }

        $state->[Parse::Marpa::Internal::NFA::AT_NULLING] = 1
            if $next_symbol->[Parse::Marpa::Internal::Symbol::NULLING];

        # the scanning transition: the transition if the position is at symbol X
        # in the RHS, via symbol X, to the state corresponding to the same
        # rule with the position incremented by 1
        # should I use ID as the key for those hashes, or NAME?
        push @{  $transition
                    ->{ $next_symbol->[Parse::Marpa::Internal::Symbol::NAME] }
                },
            $NFA_by_item[$rule_id][ $position + 1 ];

        # the prediction transitions: transitions if the position is at symbol X
        # in the RHS, via the empty symbol, to all states with X on the LHS and
        # position 0
        RULE:
        for my $predicted_rule (
            @{ $next_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
        {
            my ( $predicted_rule_id, $useful ) = @{$predicted_rule}[
                Parse::Marpa::Internal::Rule::ID,
                Parse::Marpa::Internal::Rule::USEFUL
            ];
            next RULE unless $useful;
            push @{ $transition->{ q{} } },
                $NFA_by_item[$predicted_rule_id][0];
        }
    }
}

# take a list of kernel NFA states, possibly with duplicates, and return
# a reference to an array of the fully built quasi-DFA (QDFA) states.
# as necessary.  The build is complete, except for transitions, which are
# left to be set up later.
sub assign_QDFA_state_set {
    my $grammar       = shift;
    my $kernel_states = shift;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my ( $trace_fh, $trace_priorities );
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_priorities =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES];
    }

    my ( $symbols, $NFA_states, $QDFA_by_name, $QDFA ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::NFA,
        Parse::Marpa::Internal::Grammar::QDFA_BY_NAME,
        Parse::Marpa::Internal::Grammar::QDFA
    ];

    my $highest_priority;

    # Track if a state has been seen.
    # Undefined if never seen.
    # Ref to an empty array if seen, but not a result
    # Ref to an array of reset origin flag, priority
    # and NFA ID, if seen and to go into result
    my @NFA_state_seen;

    # pre-allocate the array
    $#NFA_state_seen = @{$NFA_states};

    # The work list is an array of work items.  Each work item
    # is an NFA state, following by an optional prediction flag.
    my @work_list = map { [ $_, 0 ] } @{$kernel_states};

    # Use index because we extend this list while processing it.
    WORK_ITEM: for ( my $i = 0; $i < @work_list; $i++ ) {

        my ( $NFA_state, $reset ) = @{ $work_list[$i] };

        my $NFA_id = $NFA_state->[Parse::Marpa::Internal::NFA::ID];
        next WORK_ITEM if defined $NFA_state_seen[$NFA_id];
        my $seen = $NFA_state_seen[$NFA_id] = [];

        my $transition =
            $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION];

        # if we are at a nulling symbol, this NFA states does NOT go into the
        # result, but all transitions go into the work list.  There should be
        # empty transition.
        if ( $NFA_state->[Parse::Marpa::Internal::NFA::AT_NULLING] ) {
            push @work_list,
                map { [ $_, $reset ] }
                    map {@{$_}} values %{$transition};
            next WORK_ITEM;
        }

        # If we are here, were have an NFA state NOT at a nulling symbol.
        # This NFA state goes into the result, and the empty transitions
        # go into the worklist as reset items.
        my $empty_transitions = $transition->{ q{} };
        if ($empty_transitions) {
            push @work_list, map { [ $_, 1 ] } @{$empty_transitions};
        }

        $reset //= 0;
        my $priority = $NFA_state->[Parse::Marpa::Internal::NFA::PRIORITY]
            if $NFA_state->[Parse::Marpa::Internal::NFA::COMPLETE];
        if ( defined $priority ) {
            $highest_priority = $priority
                if not defined $highest_priority
                    or $priority gt $highest_priority;
        }
        push @{$seen}, $reset, $priority, $NFA_id;

    }    # WORK_ITEM

    $highest_priority //= pack 'NN', 0, 0;

    my @result_data = map { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map {
        $_->[1] //= $highest_priority;
        [ $_, ( (pack 'N', $_->[0] ) . $_->[1] ) ]
        } grep { defined $_ and scalar @{$_} } @NFA_state_seen;

    # this is a fake record with an
    # "impossible" value for the reset flag to force a
    # control break at the last record
    push @result_data, [-1];

    # this will hold the QDFA state set,
    # which is the result
    my @result_states = ();

    # Below is "control break logic", which was big in the days of tape sorts
    # (yes, I'm that old).  Anyway, it's fast in Perl, will be really fast in
    # C and I think actually easier to figure out than the alternative --
    # which is something like references to arrays of hash of references.

    my $old_reset = -2;    # -2 is an "impossible" value
    my $old_priority;
    my @NFA_ids = ();

    # result data is an array of the "records"
    DATUM: for my $result_data (@result_data) {

        my ( $reset, $priority, $NFA_id ) = @{$result_data};

        # if no "control break"
        if ( $old_reset == $reset and $old_priority eq $priority ) {
            push @NFA_ids, $NFA_id;
            next DATUM;
        }

        # here what's called the "control break", where the record key changes
        if (@NFA_ids) {
            my $name = join ',', @NFA_ids;
            my $QDFA_state = $QDFA_by_name->{$name};

            # this is a new QDFA state -- create it
            unless ($QDFA_state) {
                my $id = scalar @{$QDFA};

                my $start_rule;
                my $lhs_list       = [];
                my $complete_rules = [];
                my $QDFA_complete  = 0;
                my $NFA_state_list = [ @{$NFA_states}[@NFA_ids] ];
                NFA_STATE: for my $NFA_state (@{$NFA_state_list}) {
                    next NFA_STATE
                        unless
                        $NFA_state->[Parse::Marpa::Internal::NFA::COMPLETE];
                    $QDFA_complete = 1;
                    my $item =
                        $NFA_state->[Parse::Marpa::Internal::NFA::ITEM];
                    my $rule =
                        $item->[Parse::Marpa::Internal::LR0_item::RULE];
                    my $lhs = $rule->[Parse::Marpa::Internal::Rule::LHS];
                    my ( $lhs_id, $lhs_is_start ) = @{$lhs}[
                        Parse::Marpa::Internal::Symbol::ID,
                        Parse::Marpa::Internal::Symbol::START
                    ];
                    $lhs_list->[$lhs_id] = 1;
                    push @{ $complete_rules->[$lhs_id] }, $rule;
                    $start_rule = $rule if $lhs_is_start;
                }
                my $new_priority =
                    $QDFA_complete ? $old_priority : (pack 'NN', 0, 0 );
                @{$QDFA_state}[
                    Parse::Marpa::Internal::QDFA::ID,
                    Parse::Marpa::Internal::QDFA::NAME,
                    Parse::Marpa::Internal::QDFA::NFA_STATES,
                    Parse::Marpa::Internal::QDFA::RESET_ORIGIN,
                    Parse::Marpa::Internal::QDFA::PRIORITY,
                    Parse::Marpa::Internal::QDFA::START_RULE,
                    ]
                    = (
                    $id, $name, $NFA_state_list, $old_reset, $new_priority,
                    $start_rule,
                    );
                $QDFA_state->[Parse::Marpa::Internal::QDFA::COMPLETE_RULES] =
                    $complete_rules;
                $QDFA_state->[Parse::Marpa::Internal::QDFA::COMPLETE_LHS] =
                    [ map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
                        @{$symbols}[ grep { $lhs_list->[$_] }
                        ( 0 .. $#{$lhs_list} ) ] ];
                if ($trace_priorities) {
                    my $string_ref =
                        Parse::Marpa::show_priority($new_priority);
                    say $trace_fh "Priority for QDFA state $id: ",
                        $string_ref ? 'undef' : ${$string_ref};
                }
                push @{$QDFA}, $QDFA_state;
                $QDFA_by_name->{$name} = $QDFA_state;
            }    # unless $QDFA_state

            push @result_states, $QDFA_state;

        }

        # reset everything for the next control break
        @NFA_ids      = ($NFA_id);
        $old_reset    = $reset;
        $old_priority = $priority;

    }    # DATUM

    return \@result_states;
}

sub create_QDFA {
    my $grammar = shift;
    my ( $symbols, $symbol_hash, $NFA, $start, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::NFA,
        Parse::Marpa::Internal::Grammar::START,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my $trace_fh;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $QDFA = $grammar->[Parse::Marpa::Internal::Grammar::QDFA] = [];
    my $NFA_s0 = $NFA->[0];

    # next QDFA state to compute transitions for
    my $next_state_id = 0;

    my $initial_NFA_states =
        $NFA_s0->[Parse::Marpa::Internal::NFA::TRANSITION]->{ q{} };
    if ( not defined $initial_NFA_states ) {
        croak('Empty NFA, cannot create QDFA');
        return;
    }
    $grammar->[Parse::Marpa::Internal::Grammar::START_STATES] =
        assign_QDFA_state_set( $grammar, $initial_NFA_states );

    # assign_QDFA_state_set extends this array, which we are
    # simultaneously going through and adding transitions.
    # There is no problem with the process of adding transitions
    # overtaking assign_QDFA_state_set: if we reach a point where
    # all transitions have been added, and we are at the end of @$QDFA
    # we are finished.
    while ( $next_state_id < scalar @{$QDFA} ) {

        # compute the QDFA state transitions from the transitions
        # of the NFA states of which it is composed
        my $NFA_to_states_by_symbol = {};

        my $QDFA_state = $QDFA->[ $next_state_id++ ];

        # aggregrate the transitions, by symbol, for every NFA state in this QDFA
        # state
        for my $NFA_state (
            @{ $QDFA_state->[Parse::Marpa::Internal::QDFA::NFA_STATES] } )
        {
            my $transition =
                $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION];
            NFA_TRANSITION:
            while ( my ( $symbol, $to_states ) = each %{$transition} ) {
                next NFA_TRANSITION if $symbol eq q{};
                push @{ $NFA_to_states_by_symbol->{$symbol} }, @{$to_states};
            }
        }    # $NFA_state

        # for each transition symbol, create the transition to the QDFA kernel state
        while ( my ( $symbol, $to_states ) = each %{$NFA_to_states_by_symbol} )
        {
            $QDFA_state->[Parse::Marpa::Internal::QDFA::TRANSITION]
                ->{$symbol} = assign_QDFA_state_set( $grammar, $to_states );
        }
    }

    return;

}

sub setup_academic_grammar {
    my $grammar = shift;
    my $rules   = $grammar->[Parse::Marpa::Internal::Grammar::RULES];

    # in an academic grammar, consider all rules useful
    for my $rule (@{$rules}) {
        $rule->[Parse::Marpa::Internal::Rule::USEFUL] = 1;
    }

    return;
}

# given a nullable symbol, create a nulling alias and make the first symbol non-nullable
sub alias_symbol {
    my $grammar         = shift;
    my $nullable_symbol = shift;
    my ( $symbol, $symbols, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
    ];
    my ( $accessible, $productive, $name, $null_value ) = @{$nullable_symbol}[
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
    ];

    # create the new, nulling symbol
    my $symbol_count = @{$symbols};
    my $alias_name =
        $nullable_symbol->[Parse::Marpa::Internal::Symbol::NAME] . '[]';
    my $alias = [];
    @{$alias}[
        Parse::Marpa::Internal::Symbol::ID,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
        ]
        = (
        $symbol_count, $alias_name, [], [],
        $accessible, $productive, 1, 1,
        $null_value
        );
    push @{$symbols}, $alias;
    weaken( $symbol->{$alias_name} = $alias );

    # turn the original symbol into a non-nullable with a reference to the new alias
    @{$nullable_symbol}[
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_ALIAS
        ]
        = ( 0, 0, $alias );
    return $alias;
}

# For efficiency, steps in the CHAF evaluation
# work on a last-is-rest principle -- productions
# with a CHAF head always return reference to an array
# of values, of which the last value is (in turn)
# a reference to an array with the "rest" of the values.
# An empty array signals that there are no more.

# rewrite as Chomsky-Horspool-Aycock Form
sub rewrite_as_CHAF {
    my $grammar = shift;
    my ( $rules, $symbols, $old_start_symbol ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::START,
    ];

    # add null aliases to symbols which need them
    my $symbol_count = @{$symbols};
    SYMBOL: for ( my $ix = 0; $ix < $symbol_count; $ix++ ) {
        my $symbol = $symbols->[$ix];
        my ( $productive, $accessible, $nulling, $nullable, $null_alias ) =
            @{$symbol}[
            Parse::Marpa::Internal::Symbol::PRODUCTIVE,
            Parse::Marpa::Internal::Symbol::ACCESSIBLE,
            Parse::Marpa::Internal::Symbol::NULLING,
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::NULL_ALIAS
            ];

        # not necessary is the symbol already has a null
        # alias
        next SYMBOL if $null_alias;

        #  we don't bother with unreachable symbols
        next SYMBOL unless $productive;
        next SYMBOL unless $accessible;

        # look for proper nullable symbols
        next SYMBOL if $nulling;
        next SYMBOL unless $nullable;

        alias_symbol( $grammar, $symbol );
    }

    # mark, or create as needed, the useful rules

    # get the initial rule count -- new rules will be added and we don't iterate
    # over them
    my $rule_count = @{$rules};
    RULE: for ( my $rule_id = 0; $rule_id < $rule_count; $rule_id++ ) {
        my $rule = $rules->[$rule_id];
        my ( $lhs, $rhs, $productive, $accessible, $nulling, $nullable,
            $priority )
            = @{$rule}[
            Parse::Marpa::Internal::Rule::LHS,
            Parse::Marpa::Internal::Rule::RHS,
            Parse::Marpa::Internal::Rule::PRODUCTIVE,
            Parse::Marpa::Internal::Rule::ACCESSIBLE,
            Parse::Marpa::Internal::Rule::NULLING,
            Parse::Marpa::Internal::Rule::NULLABLE,
            Parse::Marpa::Internal::Rule::PRIORITY,
            ];
        my ( $user_priority, $internal_priority ) = unpack 'NN', $priority;

        # unreachable and nulling rules are useless
        next RULE unless $productive;
        next RULE unless $accessible;
        next RULE if $nulling;

        # Keep track of whether the lhs side of any new rules we create should
        # be nullable.  If any symbol in a production is not nullable, the lhs
        # is not nullable.  If the original production is nullable, all symbols
        # are nullable, all subproductions will be, and all new lhs's should be.
        # But even if the original production is not nullable, some of the
        # subproductions may be.  These will always be in a series starting from
        # the far right.

        # Going from right to left,
        # once the first non-nullable symbol is encountered,
        # that subproduction is non-nullable,
        # that lhs will be non-nullable, and since that
        # new lhs is on the far rhs of subsequent (going left) subproductions,
        # all subsequent subproductions and their lhs's will be non-nullable.
        #
        # Finally, in one more complication, remember that the nullable flag
        # was unset if a nullable was aliased.  So we need to check both the
        # NULL_ALIAS (for proper nullables) and the NULLING flags to see if
        # the original rule was nullable.

        my $last_nonnullable = -1;
        my $proper_nullables = [];
        RHS_SYMBOL: for ( my $ix = 0; $ix <= $#{$rhs}; $ix++ ) {
            my $symbol = $rhs->[$ix];
            my ( $null_alias, $nulling, $null_value ) = @{$symbol}[
                Parse::Marpa::Internal::Symbol::NULL_ALIAS,
                Parse::Marpa::Internal::Symbol::NULLING,
                Parse::Marpa::Internal::Symbol::NULL_VALUE,
            ];
            next RHS_SYMBOL if $nulling;
            if ($null_alias) {
                push @{$proper_nullables}, $ix;
                next RHS_SYMBOL;
            }
            $last_nonnullable = $ix;
        }

        # we found no properly nullable symbols in the RHS, so this rule is useful without
        # any changes
        if ( @{$proper_nullables} == 0 ) {
            $rule->[Parse::Marpa::Internal::Rule::USEFUL] = 1;
            next RULE;
        }

        # The left hand side of the first subproduction is the lhs of the original rule
        my $subp_lhs   = $lhs;
        my $subp_start = 0;

        # break this production into subproductions with a fixed number of proper nullables,
        # then factor out the proper nullables into a set of productions
        # with only non-nullable and nulling symbols.
        SUBPRODUCTION: for ( ;; ) {

            my $subp_end;
            my $proper_nullable0      = $proper_nullables->[0];
            my $subp_proper_nullable0 = $proper_nullable0 - $subp_start;
            my $proper_nullable1;
            my $subp_proper_nullable1;
            my $subp_factor0_rhs;
            my $next_subp_lhs;

            SETUP_SUBPRODUCTION: {

                if ( @{$proper_nullables} == 1 ) {
                    $subp_end = $#{$rhs};
                    $subp_factor0_rhs =
                        [ @{$rhs}[ $subp_start .. $subp_end ] ];
                    $proper_nullables = [];
                    last SETUP_SUBPRODUCTION;
                }

                $proper_nullable1      = $proper_nullables->[1];
                $subp_proper_nullable1 = $proper_nullable1 - $subp_start;

                if ( @{$proper_nullables} == 2 ) {
                    $subp_end = $#{$rhs};
                    $subp_factor0_rhs =
                        [ @{$rhs}[ $subp_start .. $subp_end ] ];
                    $proper_nullables = [];
                    last SETUP_SUBPRODUCTION;
                }

                # The following subproduction is non-nullable.
                # TODO: Has this code been tried yet? ( 15 Jan 2008)
                if ( $proper_nullable1 < $last_nonnullable ) {
                    $subp_end = $proper_nullable1;
                    splice @{$proper_nullables}, 0, 2;

                    my $unique_name_piece = sprintf '[x%x]',
                        (   scalar @{
                                $grammar->[
                                    Parse::Marpa::Internal::Grammar::SYMBOLS]
                                }
                        );
                    $next_subp_lhs = assign_symbol( $grammar,
                        $lhs->[Parse::Marpa::Internal::Symbol::NAME] . '[R'
                            . $rule_id . ':'
                            . ( $subp_end + 1 ) . ']'
                            . $unique_name_piece );
                    @{$next_subp_lhs}[
                        Parse::Marpa::Internal::Symbol::NULLABLE,
                        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
                        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
                        Parse::Marpa::Internal::Symbol::NULLING,
                        ]
                        = ( 0, 1, 1, 0 );
                    $subp_factor0_rhs = [
                        @{$rhs}[ $subp_start .. $subp_end ],
                        $next_subp_lhs
                    ];
                    last SETUP_SUBPRODUCTION;
                }

                # if we got this far we have 3 or more proper nullables, and the next
                # subproduction is nullable
                $subp_end = $proper_nullable1 - 1;
                shift @{$proper_nullables};

                my $unique_name_piece = sprintf '[x%x]',
                    (   scalar @{
                            $grammar
                                ->[Parse::Marpa::Internal::Grammar::SYMBOLS]
                            }
                    );
                $next_subp_lhs = assign_symbol( $grammar,
                          $lhs->[Parse::Marpa::Internal::Symbol::NAME] . '[R'
                        . $rule_id . ':'
                        . ( $subp_end + 1 ) . ']'
                        . $unique_name_piece );
                @{$next_subp_lhs}[
                    Parse::Marpa::Internal::Symbol::NULLABLE,
                    Parse::Marpa::Internal::Symbol::ACCESSIBLE,
                    Parse::Marpa::Internal::Symbol::PRODUCTIVE,
                    Parse::Marpa::Internal::Symbol::NULLING,

                    # Parse::Marpa::Internal::Symbol::NULL_VALUE,
                    ] = ( 1, 1, 1, 0, );
                my $nulling_subp_lhs =
                    alias_symbol( $grammar, $next_subp_lhs );
                $nulling_subp_lhs
                    ->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING] =
                    [ @{$rhs}[ ( $subp_end + 1 ) .. $#{$rhs} ] ];
                $subp_factor0_rhs =
                    [ @{$rhs}[ $subp_start .. $subp_end ], $next_subp_lhs ];

            }    # SETUP_SUBPRODUCTION

            my $factored_rhs = [$subp_factor0_rhs];

            FACTOR: {

                # We have additional factored productions if
                # 1) there is more than one proper nullable;
                # 2) there's only one, but replacing it with a nulling symbol will
                #    not make the entire production nulling
                #
                # Here and below we use the nullable flag to establish whether a
                # factored subproduction rhs would be nulling, on this principle:
                #
                # If substituting nulling symbols for all proper nullables does not
                # make a production nulling, then it is not nullable, and vice versa.

                last FACTOR if $nullable and not defined $proper_nullable1;

                # The second factored production, with a nulling symbol substituted for
                # the first proper nullable.
                # and nulling it would make this factored subproduction nulling, don't
                # bother.
                $factored_rhs->[1] = [@{$subp_factor0_rhs}];
                $factored_rhs->[1]->[$subp_proper_nullable0] =
                    $subp_factor0_rhs->[$subp_proper_nullable0]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

                # The third factored production, with a nulling symbol replacing the
                # second proper nullable.  Make sure there ARE two proper nullables.
                last FACTOR unless defined $proper_nullable1;
                $factored_rhs->[2] = [@{$subp_factor0_rhs}];
                $factored_rhs->[2]->[$subp_proper_nullable1] =
                    $subp_factor0_rhs->[$subp_proper_nullable1]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

                # The fourth and last factored production, with a nulling symbol replacing
                # both proper nullables.  We don't include it if it results in a nulling
                # production.
                last FACTOR if $nullable;
                $factored_rhs->[3] = [ @{ $factored_rhs->[2] } ];
                $factored_rhs->[3]->[$subp_proper_nullable0] =
                    $subp_factor0_rhs->[$subp_proper_nullable0]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

            }    # FACTOR

            for ( my $ix = 0; $ix <= $#{$factored_rhs}; $ix++ ) {
                my $factor_rhs = $factored_rhs->[$ix];

                # No need to bother putting together values
                # if the rule's closure is not defined
                # and the values would all be discarded

                # figure out which closure to use
                # if the LHS is the not LHS of the original rule, we have a
                # special CHAF header
                my $has_chaf_lhs = ( $subp_lhs != $lhs );

                # if a CHAF LHS was created for the next subproduction,
                # there is a CHAF continuation for this subproduction.
                # It applies to this factor if there is one of the first two
                # factors of more than two.
                my $has_chaf_rhs = $next_subp_lhs;

                # Add new rule.   In assigning internal priority:
                # The first factored production is
                # highest, last is lowest, but middle two are
                # reversed.
                my $new_rule =
                    add_rule( $grammar, $subp_lhs, $factor_rhs, undef,
                    (pack 'NN', $user_priority, @{ [qw(3 1 2 0)] }[$ix] ) );

                @{$new_rule}[
                    Parse::Marpa::Internal::Rule::USEFUL,
                    Parse::Marpa::Internal::Rule::ACCESSIBLE,
                    Parse::Marpa::Internal::Rule::PRODUCTIVE,
                    Parse::Marpa::Internal::Rule::NULLABLE,
                    Parse::Marpa::Internal::Rule::NULLING,
                    Parse::Marpa::Internal::Rule::HAS_CHAF_LHS,
                    Parse::Marpa::Internal::Rule::HAS_CHAF_RHS,
                    ]
                    = ( 1, 1, 1, 0, 0, $has_chaf_lhs, $has_chaf_rhs, );

                $new_rule->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE] =
                    $rule;
                $new_rule->[Parse::Marpa::Internal::Rule::ACTION] =
                    $rule->[Parse::Marpa::Internal::Rule::ACTION];

            }    # for each factored rhs

            # no more
            last SUBPRODUCTION unless $next_subp_lhs;
            $subp_lhs   = $next_subp_lhs;
            $subp_start = $subp_end + 1;
            $nullable   = $subp_start > $last_nonnullable;

        }    # SUBPRODUCTION

    }    # RULE

    # Create a new start symbol
    my ( $productive, $null_value ) = @{$old_start_symbol}[
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
    ];
    my $new_start_symbol =
        assign_symbol( $grammar,
        $old_start_symbol->[Parse::Marpa::Internal::Symbol::NAME] . "[']" );
    @{$new_start_symbol}[
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::START,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
        ]
        = ( $productive, 1, 1, $null_value );

    # Create a new start rule
    my $new_start_rule =
        add_rule( $grammar, $new_start_symbol, [$old_start_symbol], undef,
        0 );
    @{$new_start_rule}[
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::ACCESSIBLE,
        Parse::Marpa::Internal::Rule::USEFUL,
        Parse::Marpa::Internal::Rule::ACTION,
        ]
        = ( $productive, 1, 1, q{ $_[0] } );

    # If we created a null alias for the original start symbol, we need
    # to create a nulling start rule
    my $old_start_alias =
        $old_start_symbol->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
    if ($old_start_alias) {
        my $new_start_alias = alias_symbol( $grammar, $new_start_symbol );
        @{$new_start_alias}[ Parse::Marpa::Internal::Symbol::START, ] = (1);
        my $new_start_rule =
            add_rule( $grammar, $new_start_alias, [], undef, 0 );

        # Nulling rules are not considered useful, but the top-level one is an exception
        @{$new_start_rule}[
            Parse::Marpa::Internal::Rule::PRODUCTIVE,
            Parse::Marpa::Internal::Rule::ACCESSIBLE,
            Parse::Marpa::Internal::Rule::USEFUL,
            ]
            = ( $productive, 1, 1, );
    }
    $grammar->[Parse::Marpa::Internal::Grammar::START] = $new_start_symbol;
    return;
}

1;

=pod

=head1 NAME

Parse::Marpa::Grammar - Marpa Grammar Objects

=head1 DESCRIPTION

Grammar objects are created with the C<new> constructor.
Rules and options may be specified when the grammar is created, or later using
the C<set> method.
Rules are most conveniently added with the C<mdl_source> named argument, which
takes a reference to a string containing an MDL grammar description as its value.
MDL (the Marpa Description Language) is detailed in L<another document|Parse::Marpa::Doc::MDL>.

MDL indirectly uses another interface, the B<plumbing interface>.
The plumbing is described in L<a document of its own|Parse::Marpa::Doc::Plumbing>.
Users who want the last word in control can use the plumbing directly,
but they will lose a lot of convenience and maintainability.
Those who need the ultimate in efficiency can get the best of both worlds by
using MDL to create a grammar,
then compiling that grammar,
as L<described below|"compile">.
The MDL parser itself uses a compiled MDL file.

Marpa needs to do extensive precompution on grammars
before they can be passed on to a recognizer or an evaluator.
The user rarely needs to perform this precomputation explicitly.
The methods which require precomputed grammars
(C<compile> and C<Parse::Marpa::Recognizer::new>),
do the precomputation themselves on a just-in-time basis.

For situations where the user needs to control the state of the grammar precisely,
such as debugging or tracing,
there is a method that explicitly precomputes a grammar: C<precompute>.
Once a grammar has been precomputed, it is frozen against many kinds of
changes.
For example, you cannot add rules to a precomputed grammar.

For their private use,
Marpa recognizers make a deep copy of the the grammar used to create them.
The deep copy is done by B<compiling> the grammar, then B<decompiling> the grammar.

Grammar compilation in Marpa means turning the grammar into a string with
Marpa's C<compile> method.
Since a compiled grammar is a string, it can be handled as one.
It can, for instance, be written to a file.

Marpa's C<decompile> static method takes a compiled grammar,
C<eval>'s it,
then tweaks it a bit to create a properly set-up grammar object.
A subsequent Marpa process can read this file, C<decompile> the string,
and continue the parse.
This would eliminate the overhead both of parsing MDL and of precomputation.
As mentioned, where efficiency is a major consideration, this will
usually be better than using the
plumbing interface.

=head1 METHODS

=head2 new

=begin Parse::Marpa::test_document:

## next display
in_misc_pl($_)

=end Parse::Marpa::test_document:

    my $grammar = new Parse::Marpa::Grammar();

Z<>

=begin Parse::Marpa::test_document:

## next display
in_equation_s_t($_)

=end Parse::Marpa::test_document:

    my $grammar = new Parse::Marpa::Grammar(
	{ max_parses => 10, mdl_source => \$source, } );

C<Parse::Marpa::Recognizer::new> has one, optional, argument --
a reference to a hash of named arguments.
It returns a new grammar object or throws an exception.

Named arguments can be Marpa options.
For these see L<Parse::Marpa::Doc::Options>.
In addition to the Marpa options,
the C<mdl_source> named argument
and the named arguments of the plumbing interface are allowed.
For details of the plumbing and its named arguments, see L<Parse::Marpa::Doc::Plumbing>.

The value of the C<mdl_source> named argument should be
a B<reference> to a string containing a description of
the grammar in the L<Marpa Demonstration Language|Parse::Marpa::MDL>.
Either the C<mdl_source> named argument or the plumbing arguments may be used
to build a grammar,
but both cannot be used to build the same grammar object.

In the C<new> and C<set> methods,
a Marpa option can be specified both directly,
as a named argument to the method,
and indirectly,
in the MDL grammar description supplied as the value of an C<mdl_source> argument.
When that happens, the value in the MDL description is applied first,
and value supplied with the method's named argument is applied after the MDL is processed.
This fits the usual intent, which is for named arguments to override MDL settings.
However, this also
means that trace settings won't be in effect until after the grammar description is
processed, and that can be too late for some of the traces.
For a way around this, see L<the C<set> method|"set">.

=head2 set

=begin Parse::Marpa::test_document:

## next display
in_ah_s_t($_)

=end Parse::Marpa::test_document:

    $grammar->set( { mdl_source => \$source } );

The C<set> method takes as its one, required, argument a reference to a hash of named arguments.
It allows Marpa options, plumbing arguments and the C<mdl_source> named argument
to be specified for an already existing grammar object.
It can be used to control the order in which named arguments are applied.

In particular, some
tracing options need to be turned on prior to specifying the grammar.
To do this, a new grammar object can be created with the trace options set,
but without a grammar specification.
At this point, tracing will be in effect,
and the C<set> method can be used to specify the grammar,
using either the C<mdl_source> named argument or the plumbing
arguments.

=head2 precompute

=begin Parse::Marpa::test_document:

## next display
in_ah_s_t($_)

=end Parse::Marpa::test_document:

    $grammar->precompute();

The C<precompute> method performs Marpa's precomputations on a grammar.
It returns the grammar object or throws an exception.

It is usually not necessary for the user to call C<precompute>.
The methods which require a precomputed grammar
(C<compile> and C<Parse::Marpa::Recognizer::new>),
if passed a grammar on which the precomputation has not been done,
perform the precomputation themselves on a "just in time" basis.
But C<precompute> can be useful in debugging and tracing,
as a way to control precisely when precomputation takes place.

=head2 compile

=begin Parse::Marpa::test_document:

## next display
in_bin_mdl($_)

=end Parse::Marpa::test_document:

    my $compiled_grammar = $grammar->compile();

The C<compile> method takes as its single argument a grammar object, and "compiles" it.
It returns a reference to the compiled grammar.
The compiled grammar is a string which was created 
using L<Data::Dumper>.
On failure, C<compile> throws an exception.

=head2 decompile

=begin Parse::Marpa::test_document:

## next 2 displays
in_misc_pl($_)

=end Parse::Marpa::test_document:

    $grammar = Parse::Marpa::Grammar::decompile($compiled_grammar, $trace_fh);

    $grammar = Parse::Marpa::Grammar::decompile($compiled_grammar);

The C<decompile> static method takes a reference to a compiled grammar as its first
argument.
Its second, optional, argument is a file handle.
The file handle argument will be used both as the decompiled grammar's trace file handle,
and for any trace messages produced by C<decompile> itself.
C<decompile> returns the decompiled grammar object unless it throws an
exception.

If the trace file handle argument is omitted,
it defaults to C<STDERR>
and the decompiled grammar's trace file handle reverts to the default for a new
grammar, which is also C<STDERR>.
The trace file handle argument is necessary because in the course of compilation,
the grammar's original trace file handle may have been lost.
For example, a compiled grammar can be written to a file and emailed.
Marpa cannot rely on finding the original trace file handle available and open
when a compiled grammar is decompiled.

When Marpa deep copies grammars internally, it uses the C<compile> and C<decompile> methods.
To preserve the trace file handle of the original grammar,
Marpa first copies the handle to a temporary,
then restores the handle using the C<trace_file_handle> argument of C<decompile>.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 LICENSE AND COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5.10.0.

=cut
