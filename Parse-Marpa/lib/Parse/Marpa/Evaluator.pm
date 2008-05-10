package Parse::Marpa::Internal::Evaluator;
use 5.010_000;

use warnings;
no warnings 'recursion';
use strict;
use integer;
use List::Util qw(max);
use English qw( -no_match_vars );

# The bocage is Marpa's structure for keeping multiple parses.
# A parse bocage is a list of or-nodes, whose child
# and-nodes must be (at most) binary.

# "Parse forests" are the structures used to keep multiple
# parses in many parsers, but Marpa
# can't use them because
# Marpa allows cyclical parses, and
# it breaks the RHS of productions into
# and-nodes of a most two symbols.
# And-nodes start in binary form
# in the Aycock-Horspool Earley items, and because
# binary and-nodes store the parses
# compactly, and allow easier tree
# traversals, I keep them that way.

# Bocage is a special type of forest,
# consisting of hedgerows deliberately cultivated
# as obstacles to cattle and armies.

# Saplings become or-nodes when they grow up.

package Parse::Marpa::Internal::Sapling;

use constant NAME     => 0;
use constant ITEM     => 1;
use constant RULE     => 2;
use constant POSITION => 3;
use constant SYMBOL   => 4;

package Parse::Marpa::Internal::And_Node;

use constant PREDECESSOR => 0;
use constant CAUSE       => 1;
use constant VALUE_REF   => 2;
use constant CLOSURE     => 3;
use constant ARGC        => 4;
use constant RULE        => 5;
use constant POSITION    => 6;

package Parse::Marpa::Internal::Or_Node;

use constant NAME      => 0;
use constant AND_NODES => 1;

package Parse::Marpa::Internal::Tree_Node;

use constant OR_NODE     => 0;
use constant CHOICE      => 1;
use constant PREDECESSOR => 2;
use constant CAUSE       => 3;
use constant DEPTH       => 4;
use constant CLOSURE     => 6;
use constant ARGC        => 7;
use constant VALUE_REF   => 8;
use constant RULE        => 9;
use constant POSITION    => 10;

package Parse::Marpa::Internal::Evaluator::Rule;

use constant CODE    => 0;
use constant CLOSURE => 1;

package Parse::Marpa::Internal::Evaluator;

use constant RECOGNIZER  => 0;
use constant PARSE_COUNT => 1;    # number of parses in an ambiguous parse
use constant OR_NODES    => 2;
use constant TREE        => 3;    # current evaluation tree
use constant RULE_DATA   => 4;
use constant PACKAGE     => 5;
use constant NULL_VALUES => 6;

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

sub run_preamble {
    my $preamble = shift;
    my $package  = shift;

    my @warnings;
    my @caller_return;
    local $SIG{__WARN__} = sub {
        push @warnings, $_[0];
        @caller_return = caller 0;
    };

    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval 'package ' . $package . ";\n" . $preamble;
    ## use critic

    my $fatal_error = $EVAL_ERROR;
    if ( $fatal_error or @warnings ) {
        Parse::Marpa::Internal::code_problems(
            $fatal_error, \@warnings,
            'evaluating preamble',
            'evaluating preamble',
            \$preamble, \@caller_return
        );
    }

    return;

}    # run_preamble

# Given symbol, returns null value, calculating it
# if necessary.
#
# Assumes all but CHAF values have already been set
sub set_null_symbol_value {
    my $null_values = shift;
    my $symbol      = shift;

    # if it's not a CHAF nulling symbol,
    # or the value is already set, use what we have
    my $chaf_nulling =
        $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
    my $symbol_id  = $symbol->[Parse::Marpa::Internal::Symbol::ID];
    my $null_value = $null_values->[$symbol_id];
    if ( not $chaf_nulling or defined $null_value ) {
        return $null_value;
    }

    # it is a CHAF nulling symbol, but needs its null value calculated.
    my @chaf_null_values = ();
    for my $rhs_symbol ( @{$chaf_nulling} ) {
        my $nulling_symbol =
            $rhs_symbol->[Parse::Marpa::Internal::Symbol::NULL_ALIAS]
            // $rhs_symbol;
        my $value = set_null_symbol_value( $null_values, $nulling_symbol );
        push @chaf_null_values, $value;
    }
    push @chaf_null_values, [];

    return ( $null_values->[$symbol_id] = \@chaf_null_values );

}    # null symbol value

sub set_null_values {
    my $grammar = shift;
    my $package = shift;

    my ( $rules, $symbols, $tracing, $default_null_value ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    my $null_values;
    $#{$null_values} = $#{$symbols};

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_actions =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_ACTIONS];
    }

    SYMBOL: for my $symbol ( @{$symbols} ) {
        next SYMBOL
            if $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        my $id = $symbol->[Parse::Marpa::Internal::Symbol::ID];
        $null_values->[$id] = $default_null_value;
    }

    # Before tackling the CHAF symbols, set null values specified in
    # empty rules.
    RULE: for my $rule ( @{$rules} ) {

        my $action = $rule->[Parse::Marpa::Internal::Rule::ACTION];

        # Set the null value of symbols from the action for their
        # empty rules
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];

        # Empty rule with action?
        if ( defined $action and @{$rhs} <= 0 ) {
            my $lhs = $rule->[Parse::Marpa::Internal::Rule::LHS];
            my $nulling_alias =
                $lhs->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
            next RULE unless defined $nulling_alias;

            my $code =
                "package $package;\n" . '@_=();' . "\n" . $action;
            my @warnings;
            my @caller_return;
            local $SIG{__WARN__} = sub {
                push @warnings, $_[0];
                @caller_return = caller 0;
            };

            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            my $null_value = eval $code;
            ## use critic

            my $fatal_error = $EVAL_ERROR;
            if ( $fatal_error or @warnings ) {
                Parse::Marpa::Internal::code_problems(
                    $fatal_error,
                    \@warnings,
                    'evaluating null value',
                    'evaluating null value for '
                        . $nulling_alias
                        ->[Parse::Marpa::Internal::Symbol::NAME],
                    \$code,
                    \@caller_return
                );
            }
            my $nulling_alias_id =
                $nulling_alias->[Parse::Marpa::Internal::Symbol::ID];
            $null_values->[$nulling_alias_id] = $null_value;

            if ($trace_actions) {
                print {$trace_fh} 'Setting null value for symbol ',
                    $nulling_alias->[Parse::Marpa::Internal::Symbol::NAME],
                    " from\n", $code, "\n",
                    ' to ', Parse::Marpa::show_value( \$null_value ), "\n"
                    or croak('Could not print to trace file');
            }

        }

    }    # RULE

    SYMBOL: for my $symbol ( @{$symbols} ) {
        next SYMBOL
            unless $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        set_null_symbol_value( $null_values, $symbol );
    }

    if ($trace_actions) {
        SYMBOL: for my $symbol ( @{$symbols} ) {
            next SYMBOL
                unless
                $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];

            my ( $name, $id ) = @{$symbol}[
                Parse::Marpa::Internal::Symbol::NAME,
                Parse::Marpa::Internal::Symbol::ID,
            ];
            print {$trace_fh}
                'Setting null value for CHAF symbol ',
                $name, ' to ', Dumper( $null_values->[$id] ),
                or croak('Could not print to trace file');
        }
    }

    return $null_values;

}    # set_null_values

sub set_actions {
    my $grammar = shift;
    my $package = shift;

    my ( $rules, $tracing, $default_action, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_ACTION,
    ];

    # need trace_fh for code problems here, even if not tracing
    my $trace_fh
         = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    my $trace_actions;
    if ($tracing) {
        $trace_actions =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_ACTIONS];
    }

    my $rule_data = [];

    RULE: for my $rule ( @{$rules} ) {

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
                $action = q{ \@_; };
                last ACTION;
            }

            # At this point has chaf rhs or lhs but not both
            if ($has_chaf_lhs) {

                $action = q{push @_, [];} . "\n" . q{\@_} . "\n";
                last ACTION;

            }

            # at this point must have chaf rhs and not a chaf lhs

            $action =
                  "    TAIL: for (;;) {\n"
                . q<        my $tail = pop @_;> . "\n"
                . q<        last TAIL unless scalar @{$tail};> . "\n"
                . q<        push @_, @{$tail};> . "\n"
		. "    } # TAIL\n"
                . $action;

        }    # ACTION

        my $rule_id = $rule->[Parse::Marpa::Internal::Rule::ID];

	if (not defined $action) {

	    if ($trace_actions) {
		print {$trace_fh} 'Setting action for rule ',
		    Parse::Marpa::brief_rule($rule), " to undef by default\n"
		    or croak('Could not print to trace file');
	    }

	    my $rule_datum;
	    $rule_datum->[Parse::Marpa::Internal::Evaluator::Rule::CODE] = "default to undef";
	    $rule_datum->[Parse::Marpa::Internal::Evaluator::Rule::CLOSURE] = \undef;
	    $rule_data->[$rule_id] = $rule_datum;
	    next RULE;
	}

        my $code =
              "sub {\n"
            . '    package '
            . $package . ";\n"
            . $action . "\n" . '}';

        if ($trace_actions) {
            print {$trace_fh} 'Setting action for rule ',
                Parse::Marpa::brief_rule($rule), " to\n", $code, "\n"
                or croak('Could not print to trace file');
        }

        my $closure;
        {
            my @warnings;
            my @caller_return;
            local $SIG{__WARN__} = sub {
                push @warnings, $_[0];
                @caller_return = caller 0;
            };

            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            $closure = eval $code;
            ## use critic

            my $fatal_error = $EVAL_ERROR;
            if ( $fatal_error or @warnings ) {
		say {$trace_fh}
		    'Problems compiling action for original rule: ',
		    Parse::Marpa::brief_original_rule($rule);
                Parse::Marpa::Internal::code_problems(
                    $fatal_error,
                    \@warnings,
                    'compiling action',
                    'compiling action for '
                        . Parse::Marpa::brief_rule($rule),
                    \$code,
                    \@caller_return
                );
            }
        }

        my $rule_datum;
        $rule_datum->[Parse::Marpa::Internal::Evaluator::Rule::CODE] = $code;
        $rule_datum->[Parse::Marpa::Internal::Evaluator::Rule::CLOSURE] =
            $closure;

	$rule_data->[$rule_id] = $rule_datum;

    }    # RULE

    return $rule_data;

}    # set_actions

sub Parse::Marpa::Evaluator::new {
    my $class         = shift;
    my $recognizer    = shift;
    my $parse_set_arg = shift;
    my $self          = bless [], $class;

    my $recognizer_class = ref $recognizer;
    my $right_class      = 'Parse::Marpa::Recognizer';
    croak(
        "Don't parse argument is class: $recognizer_class; should be: $right_class"
    ) unless $recognizer_class eq $right_class;

    defined $recognizer->[Parse::Marpa::Internal::Recognizer::EVALUATOR]
        and croak('Recognizer already in use by Evaluator');

    weaken( $recognizer->[Parse::Marpa::Internal::Recognizer::EVALUATOR] =
            $self );

    my ( $grammar, $earley_sets, ) = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
    ];

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    my $trace_iterations;

    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_iterations = $grammar
            ->[Parse::Marpa::Internal::Grammar::TRACE_ITERATIONS];
    }

    local ($Data::Dumper::Terse) = 1;

    my $online = $grammar->[Parse::Marpa::Internal::Grammar::ONLINE];
    if ( not $online ) {
        Parse::Marpa::Recognizer::end_input($recognizer);
    }
    my $default_parse_set =
        $recognizer->[Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET];

    $self->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT] = 0;
    $self->[Parse::Marpa::Internal::Evaluator::OR_NODES]    = [];

    my $current_parse_set = $parse_set_arg // $default_parse_set;

    # Look for the start item and start rule
    my $earley_set = $earley_sets->[$current_parse_set];

    my $start_item;
    my $start_rule;
    my $start_state;

    EARLEY_ITEM: for my $item ( @{$earley_set} ) {
        $start_state = $item->[Parse::Marpa::Internal::Earley_item::STATE];
        $start_rule =
            $start_state->[Parse::Marpa::Internal::QDFA::START_RULE];
        next EARLEY_ITEM unless $start_rule;
        $start_item = $item;
        last EARLEY_ITEM;
    }

    return unless $start_rule;

    @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::START_ITEM,
        Parse::Marpa::Internal::Recognizer::CURRENT_PARSE_SET,
        ]
        = ( $start_item, $current_parse_set );

    $self->[Parse::Marpa::Internal::Evaluator::RECOGNIZER] = $recognizer;

    state $parse_number = 0;
    my $package = $self->[Parse::Marpa::Internal::Evaluator::PACKAGE] =
        sprintf 'Parse::Marpa::E_%x', $parse_number++;
    my $preamble = $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE];
    defined $preamble and run_preamble( $preamble, $package );
    my $null_values =
        $self->[Parse::Marpa::Internal::Evaluator::NULL_VALUES] =
        set_null_values( $grammar, $package );
    my $rule_data = $self->[Parse::Marpa::Internal::Evaluator::RULE_DATA] =
        set_actions( $grammar, $package );

    my $start_symbol = $start_rule->[Parse::Marpa::Internal::Rule::LHS];
    my ( $nulling, $symbol_id ) = @{$start_symbol}[
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::ID,
    ];
    my $start_null_value = $null_values->[$symbol_id];

    # deal with a null parse as a special case
    if ($nulling) {
        my $and_node = [];

        my $closure =
            $rule_data->[ $start_rule->[Parse::Marpa::Internal::Rule::ID] ]
            ->[Parse::Marpa::Internal::Evaluator::Rule::CLOSURE];

        @{$and_node}[
            Parse::Marpa::Internal::And_Node::VALUE_REF,
            Parse::Marpa::Internal::And_Node::CLOSURE,
            Parse::Marpa::Internal::And_Node::ARGC,
            Parse::Marpa::Internal::And_Node::RULE,
            Parse::Marpa::Internal::And_Node::POSITION,
            ]
            = (
            \$start_null_value,
            $closure,
            ( scalar @{ $start_rule->[Parse::Marpa::Internal::Rule::RHS] } ),
            $start_rule,
	    0,
            );

        my $or_node = [];
        $or_node->[Parse::Marpa::Internal::Or_Node::NAME] =
            $start_item->[Parse::Marpa::Internal::Earley_item::NAME];
        $or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES] = [$and_node];

        $self->[OR_NODES] = [$or_node];

        return $self;

    }    # if $nulling

    my @saplings;
    my %or_node_by_name;
    my $start_sapling = [];
    {
        my $name = $start_item->[Parse::Marpa::Internal::Earley_item::NAME];
        my $symbol_id = $start_symbol->[Parse::Marpa::Internal::Symbol::ID];
        $name .= 'L' . $symbol_id;
        $start_sapling->[Parse::Marpa::Internal::Sapling::NAME] = $name;
    }
    $start_sapling->[Parse::Marpa::Internal::Sapling::ITEM] = $start_item;
    $start_sapling->[Parse::Marpa::Internal::Sapling::SYMBOL] =
        $start_symbol;
    push @saplings, $start_sapling;

    my $i = 0;
    SAPLING: while (1) {

        my ( $sapling_name, $item, $symbol, $rule, $position ) =
            @{ $saplings[ $i++ ] }[
            Parse::Marpa::Internal::Sapling::NAME,
            Parse::Marpa::Internal::Sapling::ITEM,
            Parse::Marpa::Internal::Sapling::SYMBOL,
            Parse::Marpa::Internal::Sapling::RULE,
            Parse::Marpa::Internal::Sapling::POSITION,
            ];

        last SAPLING unless defined $item;

        # If we don't have a current rule, we need to get one or
        # more rules, and deduce the position and a new symbol from
        # them.
        my @rule_work_list;

        # If we have a rule and a position, get the current symbol
        if ( defined $position ) {

            my $symbol =
                $rule->[Parse::Marpa::Internal::Rule::RHS]->[$position-1];
            push @rule_work_list, [ $rule, $position, $symbol ];

        }
        else {    # if not defined $position

            my $lhs_id = $symbol->[Parse::Marpa::Internal::Symbol::ID];
            my $state  = $item->[Parse::Marpa::Internal::Earley_item::STATE];
            for my $rule (
                @{  $state->[Parse::Marpa::Internal::QDFA::COMPLETE_RULES]
                        ->[$lhs_id];
                }
                )
            {

                my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];
                my $closure =
                    $rule_data->[ $rule->[Parse::Marpa::Internal::Rule::ID] ]
                    ->[Parse::Marpa::Internal::Evaluator::Rule::CLOSURE];

                my $last_position = @{$rhs};
                push @rule_work_list,
                    [
                    $rule,                  $last_position,
                    $rhs->[$last_position-1], $closure
                    ];

            }    # for my $rule

        }    # not defined $position

        my @and_nodes;

        my $item_name = $item->[Parse::Marpa::Internal::Earley_item::NAME];

        RULE: for my $rule_work_item (@rule_work_list) {

            my ( $rule, $position, $symbol, $closure ) = @{$rule_work_item};

            my ( $rule_id, $rhs ) = @{$rule}[
                Parse::Marpa::Internal::Rule::ID,
                Parse::Marpa::Internal::Rule::RHS
            ];
            my $rule_length = @{$rhs};

            my @work_list;
            if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLING] ) {
                my $symbol_id = $symbol->[Parse::Marpa::Internal::Symbol::ID];
                my $null_value = $null_values->[$symbol_id];
                @work_list = ( [ $item, undef, \$null_value, ] );
            }
            else {
                @work_list = (
                    (   map { [ $_->[0], undef, \( $_->[1] ) ] } @{
                            $item->[
                                Parse::Marpa::Internal::Earley_item::TOKENS
                            ]
                            }
                    ),
                    (   map { [ $_->[0], $_->[1] ] } @{
                            $item
                                ->[Parse::Marpa::Internal::Earley_item::LINKS]
                            }
                    )
                );
            }

            for my $work_item (@work_list) {

                my ( $predecessor, $cause, $value_ref ) = @{$work_item};

                my $predecessor_name;

                if ( $position > 1 ) {

                    $predecessor_name =
                        $predecessor
                        ->[Parse::Marpa::Internal::Earley_item::NAME]
			. "R$rule_id:$position";

                    unless ( $predecessor_name ~~ %or_node_by_name ) {

                        $or_node_by_name{$predecessor_name} = [];

                        my $sapling = [];
                        @{$sapling}[
                            Parse::Marpa::Internal::Sapling::NAME,
                            Parse::Marpa::Internal::Sapling::RULE,
                            Parse::Marpa::Internal::Sapling::POSITION,
                            Parse::Marpa::Internal::Sapling::ITEM,
                            ]
                            = (
                            $predecessor_name, $rule, $position - 1,
                            $predecessor,
                            );

                        push @saplings, $sapling;

                    }    # $predecessor_name ~~ %or_node_by_name

                }    # if position > 0

                my $cause_name;

                if ( defined $cause ) {

                    my $symbol_id =
                        $symbol->[Parse::Marpa::Internal::Symbol::ID];

                    $cause_name =
                          $cause->[Parse::Marpa::Internal::Earley_item::NAME]
                        . 'L'
                        . $symbol_id;

                    unless ( $cause_name ~~ %or_node_by_name ) {

                        $or_node_by_name{$cause_name} = [];

                        my $sapling = [];
                        @{$sapling}[
                            Parse::Marpa::Internal::Sapling::NAME,
                            Parse::Marpa::Internal::Sapling::SYMBOL,
                            Parse::Marpa::Internal::Sapling::ITEM,
                            ]
                            = ( $cause_name, $symbol, $cause, );

                        push @saplings, $sapling;

                    }    # $cause_name ~~ %or_node_by_name

                }    # if cause

                my $and_node = [];
                @{$and_node}[
                    Parse::Marpa::Internal::And_Node::PREDECESSOR,
                    Parse::Marpa::Internal::And_Node::CAUSE,
                    Parse::Marpa::Internal::And_Node::VALUE_REF,
                    Parse::Marpa::Internal::And_Node::CLOSURE,
                    Parse::Marpa::Internal::And_Node::ARGC,
                    Parse::Marpa::Internal::And_Node::RULE,
                    Parse::Marpa::Internal::And_Node::POSITION,
                    ]
                    = (
                    $predecessor_name, $cause_name, $value_ref, $closure,
                    $rule_length, $rule, $position,
                    );

                push @and_nodes, $and_node;

            }    # for work_item

        }    # RULE

        my $or_node = [];
        $or_node->[Parse::Marpa::Internal::Or_Node::NAME] = $sapling_name;
        $or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES] = \@and_nodes;
        push @{ $self->[OR_NODES] }, $or_node;
        $or_node_by_name{$sapling_name} = $or_node;

    }    # SAPLING

    # resolve links in the bocage
    for my $and_node (
        map { @{ $_->[Parse::Marpa::Internal::Or_Node::AND_NODES] } }
        @{ $self->[OR_NODES] } )
    {
        FIELD:
        for my $field (
            Parse::Marpa::Internal::And_Node::PREDECESSOR,
            Parse::Marpa::Internal::And_Node::CAUSE,
            )
        {
            my $name = $and_node->[$field];
            next FIELD unless defined $name;
            $and_node->[$field] = $or_node_by_name{$name};
        }

    }

    return $self;

}

sub Parse::Marpa::show_bocage {
    my $evaler  = shift;
    my $verbose = shift;

    my ( $parse_count, $or_nodes, $package, ) = @{$evaler}[
        Parse::Marpa::Internal::Evaluator::PARSE_COUNT,
        Parse::Marpa::Internal::Evaluator::OR_NODES,
        Parse::Marpa::Internal::Evaluator::PACKAGE,
    ];

    local $Data::Dumper::Terse = 1;

    my $text =
        'package: ' . $package . '; parse count: ' . $parse_count . "\n";

    for my $or_node ( @{ $evaler->[OR_NODES] } ) {

        my $lhs = $or_node->[Parse::Marpa::Internal::Or_Node::NAME];

        for my $and_node (
            @{ $or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES] } )
        {

            my ( $predecessor, $cause, $value_ref, $closure,
		$argc, $rule, $position,
	    ) = @{$and_node}[
                Parse::Marpa::Internal::And_Node::PREDECESSOR,
                Parse::Marpa::Internal::And_Node::CAUSE,
                Parse::Marpa::Internal::And_Node::VALUE_REF,
                Parse::Marpa::Internal::And_Node::CLOSURE,
                Parse::Marpa::Internal::And_Node::ARGC,
                Parse::Marpa::Internal::And_Node::RULE,
                Parse::Marpa::Internal::And_Node::POSITION,
	    ];

            my @rhs = ();

            if ($predecessor) {
                push @rhs,
                    $predecessor->[Parse::Marpa::Internal::Or_Node::NAME];
            }    # predecessor

            if ($cause) {
                push @rhs, $cause->[Parse::Marpa::Internal::Or_Node::NAME];
            }    # cause

            if ( defined $value_ref ) {
                my $value_as_string = Dumper( ${$value_ref} );
                chomp $value_as_string;
                push @rhs, $value_as_string;
            }    # value

            $text .= $lhs . ' ::= ' . join( q{ }, @rhs ) . "\n";

            if ($verbose) {
                $text .= '    item: ' . Parse::Marpa::show_dotted_rule($rule, $position) . "\n";
                $text .= '    argc=' . $argc;
                if ( defined $closure ) {
                    $text .= '; closure=' . Dumper($closure);
                }
                else {
                    $text .= "\n";
                }
            }

        }    # for my $and_node;

    }    # for my $or_node

    return $text;
}

sub Parse::Marpa::show_tree {
    my $evaler  = shift;
    my $verbose = shift;

    my ( $tree, ) = @{$evaler}[ Parse::Marpa::Internal::Evaluator::TREE, ];

    local $Data::Dumper::Terse = 1;

    my $text = q{};

    for my $tree_node ( @{$tree} ) {

        my ($or_node, $choice,    $predecessor,
            $cause,   $depth,     $closure,
            $argc,    $value_ref, $rule,
	    $position,
	) = @{$tree_node}[
            Parse::Marpa::Internal::Tree_Node::OR_NODE,
            Parse::Marpa::Internal::Tree_Node::CHOICE,
            Parse::Marpa::Internal::Tree_Node::PREDECESSOR,
            Parse::Marpa::Internal::Tree_Node::CAUSE,
            Parse::Marpa::Internal::Tree_Node::DEPTH,
            Parse::Marpa::Internal::Tree_Node::CLOSURE,
            Parse::Marpa::Internal::Tree_Node::ARGC,
            Parse::Marpa::Internal::Tree_Node::VALUE_REF,
            Parse::Marpa::Internal::Tree_Node::RULE,
            Parse::Marpa::Internal::Tree_Node::POSITION,
	];

        $text
            .= 'Tree Node: '
            . $or_node->[Parse::Marpa::Internal::Or_Node::NAME]
            . "[$choice]"
            . "; Depth=$depth; Argc=$argc\n";
        $text
            .= '    Rule: '
            . Parse::Marpa::show_dotted_rule($rule, $position)
	    . "\n";
        $text
            .= '    Predecessor: '
            . $predecessor->[Parse::Marpa::Internal::Tree_Node::OR_NODE]
		->[Parse::Marpa::Internal::Or_Node::NAME] . "\n"
            if defined $predecessor;
        $text
            .= '    Cause: '
            . $cause->[Parse::Marpa::Internal::Tree_Node::OR_NODE]
		->[Parse::Marpa::Internal::Or_Node::NAME] . "\n"
            if defined $cause;
        if ( $verbose and defined $value_ref ) {
            $text .= '    Value: ' . Dumper( ${$value_ref} );
        }
        if ( $verbose and defined $closure ) {
            $text .= "    Closure: $closure\n";
        }

    }    # $tree_node

    return $text;

}

# Apparently perlcritic has a bug and doesn't see the final return
## no critic (Subroutines::RequireFinalReturn)
sub Parse::Marpa::Evaluator::value {
## use critic

    my $evaler = shift;
    my $recognizer =
        $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    croak('No parse supplied') unless defined $evaler;
    my $evaler_class = ref $evaler;
    my $right_class  = 'Parse::Marpa::Evaluator';
    croak(
        "Don't parse argument is class: $evaler_class; should be: $right_class"
    ) unless $evaler_class eq $right_class;

    my ( $grammar, ) =
        @{$recognizer}[ Parse::Marpa::Internal::Recognizer::GRAMMAR, ];

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    my $trace_values;
    my $trace_iterations;
    if ($tracing) {
        $trace_values =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_VALUES];
        $trace_iterations = $grammar
            ->[Parse::Marpa::Internal::Grammar::TRACE_ITERATIONS];
    }

    local ($Data::Dumper::Terse) = 1;

    my ( $bocage, $tree, $rule_data, $null_values ) = @{$evaler}[
        Parse::Marpa::Internal::Evaluator::OR_NODES,
        Parse::Marpa::Internal::Evaluator::TREE,
        Parse::Marpa::Internal::Evaluator::RULE_DATA,
        Parse::Marpa::Internal::Evaluator::NULL_VALUES,
    ];

    my $max_parses = $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES];
    my $parse_count =
        $evaler->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT]++;
    if ( $max_parses > 0 && $parse_count >= $max_parses ) {
        croak("Maximum parse count ($max_parses) exceeded");
    }

    # Keep returning
    given ($parse_count) {

        # When called the first time, create the tree
        when (0) {
            $evaler->[Parse::Marpa::Internal::Evaluator::TREE] = $tree = [];
        }

        # If we are called with empty tree, we've
        # already returned all the parses.  Patiently keep
        # returning failure.
        default { return if @{$tree} == 0; }

    }    # given $tree

    TREE: while (1) {

        my @traversal_stack;

        # trace position in tree starting at top of stack (end of array)
        # will be used (negated) as argument to splice.
        my $tree_position = 0;
        my @last_position_by_depth;
        my @uniterated_leaf_side = ();

        # Did we iterate the tree?
        my $tree_was_iterated = 0;

        POP_TREE_NODE: for my $node ( reverse @{$tree} ) {

            $tree_position++;

            my ( $choice, $or_node, $depth ) = @{$node}[
                Parse::Marpa::Internal::Tree_Node::CHOICE,
                Parse::Marpa::Internal::Tree_Node::OR_NODE,
                Parse::Marpa::Internal::Tree_Node::DEPTH,
            ];

            my $and_nodes =
                $or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES];

            $choice++;

            if ( $choice >= @{$and_nodes} ) {
                $last_position_by_depth[$depth] = $tree_position;
                next POP_TREE_NODE;
            }

            if ($trace_iterations) {
                say {$trace_fh}
                    'Iteration ',
                    $choice,
                    ' tree node ',
                    $or_node->[Parse::Marpa::Internal::Or_Node::NAME],
                    or croak('print to trace handle failed');
            }

            my $new_tree_node;
            @{$new_tree_node}[
                Parse::Marpa::Internal::Tree_Node::CHOICE,
                Parse::Marpa::Internal::Tree_Node::OR_NODE,
                Parse::Marpa::Internal::Tree_Node::DEPTH,
                ]
                = ( $choice, $or_node, $depth, );
            push @traversal_stack, $new_tree_node;

            # The iterated part of the tree will have
            # uniterated parts on the root and leaf side.
            # The root side will be left on the stack,
            # when the old nodes are splice'd off.
            # The leaf side is copied and saved here.
            my $leaf_side_start_position =
                max(
		    grep { defined $_ } @last_position_by_depth[0 .. $depth]
		);
            my $nodes_iterated = $tree_position;
            if ( defined $leaf_side_start_position ) {
                @uniterated_leaf_side = splice @{$tree},
                    -$leaf_side_start_position;
                $nodes_iterated -= $leaf_side_start_position;
            }
            splice @{$tree}, -$nodes_iterated;

            if ($trace_iterations) {
                say {$trace_fh} 'Nodes iterated: ', $nodes_iterated,
                    '; not iterated on root side: ', scalar @{$tree},
                    '; not iterated on leaf side: ',
                    scalar @uniterated_leaf_side
                    or croak('print to trace handle failed');
            }

            $tree_was_iterated++;

            last POP_TREE_NODE;

        }    # POP_TREE_NODE

        # First time through, there will be an empty tree,
        # nothing to iterate, and therefore no new_tree_node.
        # So get things going with an initial node.
        if ( $parse_count <= 0 ) {

            my $new_tree_node;
            @{$new_tree_node}[
                Parse::Marpa::Internal::Tree_Node::OR_NODE,
                Parse::Marpa::Internal::Tree_Node::DEPTH,
                ]
                = ( $bocage->[0], 0, );
            @traversal_stack = ($new_tree_node);

        }
        elsif ( not $tree_was_iterated ) {

            # set the tree to empty
            # and return failure
            $tree = [];
            return;

        }    # not $tree_was_iterated

        # A preorder traversal, to build the tree
        # Start with the first or-node of the bocage.
        # The code below assumes the or-node is the first field of the tree node.
        OR_NODE: while (@traversal_stack) {

            my $new_tree_node = pop @traversal_stack;

            my ( $or_node, $choice, $depth ) = @{$new_tree_node}[
                Parse::Marpa::Internal::Tree_Node::OR_NODE,
                Parse::Marpa::Internal::Tree_Node::CHOICE,
                Parse::Marpa::Internal::Tree_Node::DEPTH,
            ];
            $choice //= 0;

            my $and_node =
                $or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES]
                ->[$choice];

            my ( $predecessor_or_node, $cause_or_node, $closure, $argc,
                $value_ref, $rule, $position, )
                = @{$and_node}[
                Parse::Marpa::Internal::And_Node::PREDECESSOR,
                Parse::Marpa::Internal::And_Node::CAUSE,
                Parse::Marpa::Internal::And_Node::CLOSURE,
                Parse::Marpa::Internal::And_Node::ARGC,
                Parse::Marpa::Internal::And_Node::VALUE_REF,
                Parse::Marpa::Internal::And_Node::RULE,
                Parse::Marpa::Internal::And_Node::POSITION,
                ];

            my $predecessor_tree_node;
            if ( defined $predecessor_or_node ) {
                @{$predecessor_tree_node}[
                    Parse::Marpa::Internal::Tree_Node::OR_NODE,
                    Parse::Marpa::Internal::Tree_Node::DEPTH
                    ]
                    = ( $predecessor_or_node, $depth + 1, );
            }

            my $cause_tree_node;
            if ( defined $cause_or_node ) {
                @{$cause_tree_node}[
                    Parse::Marpa::Internal::Tree_Node::OR_NODE,
                    Parse::Marpa::Internal::Tree_Node::DEPTH
                    ]
                    = ( $cause_or_node, $depth + 1, );
            }

            @{$new_tree_node}[
                Parse::Marpa::Internal::Tree_Node::CHOICE,
                Parse::Marpa::Internal::Tree_Node::PREDECESSOR,
                Parse::Marpa::Internal::Tree_Node::CAUSE,
                Parse::Marpa::Internal::Tree_Node::CLOSURE,
                Parse::Marpa::Internal::Tree_Node::ARGC,
                Parse::Marpa::Internal::Tree_Node::RULE,
                Parse::Marpa::Internal::Tree_Node::VALUE_REF,
                Parse::Marpa::Internal::Tree_Node::POSITION,
                ]
                = (
                $choice, $predecessor_tree_node, $cause_tree_node, $closure,
                $argc, $rule, $value_ref, $position,
                );

            if ($trace_iterations) {
                my $value_description = "\n";
                $value_description = '; value=' . Dumper( ${$value_ref} )
                    if defined $value_ref;
                print {$trace_fh}
                    'Pushing tree node ',
                    $or_node->[Parse::Marpa::Internal::Or_Node::NAME],
		    "[$choice]: ",
                    Parse::Marpa::show_dotted_rule($rule, $position),
		    $value_description
                    or croak('print to trace handle failed');
            }

            push @{$tree}, $new_tree_node;
            undef $new_tree_node;
            push @traversal_stack,
                grep { defined $_ }
                ( $predecessor_tree_node, $cause_tree_node );

        }    # OR_NODE

        # Put the uniterated leaf side of the tree back on the stack.
        push @{$tree}, @uniterated_leaf_side;

        my @evaluation_stack;

        TREE_NODE: for my $node ( reverse @{$tree} ) {

            my ( $closure, $value_ref, $argc ) = @{$node}[
                Parse::Marpa::Internal::Tree_Node::CLOSURE,
                Parse::Marpa::Internal::Tree_Node::VALUE_REF,
                Parse::Marpa::Internal::Tree_Node::ARGC,
            ];

            if ( defined $value_ref ) {

                push @evaluation_stack, $value_ref;

                if ($trace_values) {
                    print {$trace_fh} 'Pushed value: ',
                        Dumper( ${$value_ref} )
                        or croak('print to trace handle failed');
                }

            }    # defined $value_ref

	    next TREE_NODE unless defined $closure;

	    if ($trace_values) {
		my ( $or_node, $rule ) = @{$node}[
		    Parse::Marpa::Internal::Tree_Node::OR_NODE,
		    Parse::Marpa::Internal::Tree_Node::RULE,
		];
		say {$trace_fh}
		    'Popping ',
		    $argc,
		    ' values to evaluate ',
		    $or_node->[Parse::Marpa::Internal::Or_Node::NAME],
		    ', rule: ',
		    Parse::Marpa::brief_rule($rule);
	    }

	    my $args =
		[ map { ${$_} } ( splice @evaluation_stack, -$argc ) ];

	    my $result;

	    my $closure_type = ref $closure;

	    if ($closure_type eq 'CODE') {

                {
                    my @warnings;
                    my @caller_return;
                    local $SIG{__WARN__} = sub {
                        push @warnings, $_[0];
                        @caller_return = caller 0;
                    };

                    $result = eval {
                        $closure->( @{$args} );
                    };

                    my $fatal_error = $EVAL_ERROR;
                    if ( $fatal_error or @warnings ) {
                        my $rule =
                            $node->[ Parse::Marpa::Internal::Tree_Node::RULE,
                            ];
                        my $code =
                            $rule_data
                            ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ]
                            ->[Parse::Marpa::Internal::Evaluator::Rule::CODE
                            ];
			say {$trace_fh}
			    'Problems computing value for original rule: ',
			    Parse::Marpa::brief_original_rule($rule);
                        Parse::Marpa::Internal::code_problems(
                            $fatal_error,
                            \@warnings,
                            'computing value',
                            'computing value for rule: '
                                . Parse::Marpa::brief_rule($rule),
                            \$code,
                            \@caller_return
                        );
                    }
                }

            } # when CODE

	    # don't document this behavior -- I'll probably want to
	    # use non-reference "closure" values for special hacks
	    # in the future.
	    elsif ($closure_type eq q{}) { # when not reference
	        $result = $closure;
	    } # when not reference

	    else { # when non-code reference
	        $result = ${$closure};
	    } # when non-code reference

	    if ($trace_values) {
		print {$trace_fh} 'Calculated and pushed value: ',
		    Dumper($result)
		    or croak('print to trace handle failed');
	    }

	    push @evaluation_stack, \$result;

        }    # TREE_NODE

        return pop @evaluation_stack;

    }    # TREE

    return;

}

1;

__END__

=pod

=head1 NAME

Parse::Marpa::Evaluator - Marpa Evaluator Objects

=head1 SYNOPSIS

    my $grammar = new Parse::Marpa::Grammar({ mdl_source => \$mdl });
    my $recce = new Parse::Marpa::Recognizer({ grammar => $grammar });
    my $fail_offset = $recce->text(\("2-0*3+1"));
    croak("Parse failed at offset $fail_offset") if $fail_offset >= 0;

    my $evaler = new Parse::Marpa::Evaluator($recce);

    for (my $i = 0; defined(my $value = $evaler->value()); $i++) {
        croak("Ambiguous parse has extra value: ", $$value, "\n")
	    if $i > $expected;
	say "Ambiguous Equation Value $i: ", $$value;
    }

=head1 DESCRIPTION

Parses are found and evaluated by Marpa's evaluator objects.
Evaluators are created with the C<new> constructor,
which requires a Marpa recognizer object.

Marpa allows ambiguous parses, so evaluator objects are iterators.
Iteration is performed with the C<next> method,
which returns a reference to the value of the next parse.
Often only one parse is needed, in which case the C<next> method is called only once.

Each Marpa recognizer should have only one evaluator using it at any one time.
If multiple evaluators
use the same recognizer at the same time,
they may produce incorrect results.

=head2 Null Values

A "null value" is the value used for a symbol's value when it is nulled in a parse.
By default, the null value is a Perl undefined.
If you want something else,
the default null value is a Marpa option (C<default_null_value>) and can be reset.

Each symbol can have its own null symbol value.
The null symbol value for any symbol is calculated using the action
specified for the empty rule which has that symbol as its left hand side.
The null symbol action is B<not> a rule action.
It's a property of the symbol, and applies whenever the symbol is nulled,
even when the symbol's empty rule is not involved.

For example, in MDL,
the following says that whenever the symbol C<A> is nulled,
its value should be a string which expresses surprise.

    A: . q{ 'Oops!  Where did I go!' }.

Null symbol actions are different from rule actions in another important way.
Null symbol actions are run at recognizer creation time and the value of the result
at that point
becomes fixed as the null symbol value.
This is different from rule actions.
During the creation of the recognizer object,
rule actions are B<compiled into closures>.
During parse evaluation,
whenever a node for that rule needs its value recalculated,
the compiled rule closure is run.
A compiled rule closure
can produce a different value every time it runs.

I treat null symbol actions differently for efficiency.
They have no child values,
and a fixed value is usually what is wanted.
If you want to calculate a symbol's null value with a closure run at parse evaluation time,
the null symbol action can return a reference to a closure.
Rules with that nullable symbol in their right hand side
can then be set up so that they run that closure.

=head3 Evaluating Null Derivations

A null derivation may consist of many steps and may contain many symbols.
Marpa's rule is that the value of a null derivation is
the null symbol value of the B<highest null symbol> in that
derivation.
This section describes in detail how a parse is evaluated,
focusing on what happens when nulled symbols are involved.

The first step in evaluating a parse is to determine which nodes
B<count> for the purpose of evaluation, and which do not.
Marpa follows these principles:

=over 4

=item 1

The start node always counts.

=item 2

Nodes count if they derive a non-empty sentence.

=item 3

All other nodes do not count.

=item 4

In evaluating a parse, Marpa uses only nodes that count.

=back

These are all consequences of the principles above:

=over 4

=item 1

The value of null derivation is the value of the highest null symbol in it.

=item 2

A nulled node counts only if it is start node.

=item 3

The value of a null parse is the null value of the start symbol.

=back

If you think some of the rules or symbols represented by nodes that don't count
are important in your grammar,
Marpa can probably accommodate your ideas.
First,
for every nullable symbol,
determine how to calculate the value which your semantics produces
when that nullable symbol is a "highest null symbol".
If it's a constant, write a null action for that symbol which returns that constant.
If your semantics do not produce a constant value by recognizer creation time,
write a null action which returns a reference to a closure
and arrange to have that closure run by the parent node.

=head3 Example

Suppose a grammar has these rules

    S: A, Y. q{ $_->[0] . ", but " . $_->[1] }. # Call me the start rule
    note: you can also call me Rule 0.

    A: . q{'A is missing'}. # Call me Rule 1

    A: B, C. q{"I'm sometimes null and sometimes not"}. # Call me Rule 2

    B: . q{'B is missing'}. # Call me Rule 3

    C: . q{'C is missing'}. # Call me Rule 4

    C: Y.  q{'C matches Y'}. # Call me Rule 5

    Y: /Z/. q{'Zorro was here'}. # Call me Rule 6

In the above MDL, the Perl 5 regex "C</Z/>" occurs on the rhs of Rule 6.
Where a regex is on the rhs of a rule, MDL internally creates a terminal symbol
to match that regex in the input text.
In this example, the MDL internal terminal symbol that
matches input text using the regex
C</Z/> will be called C<Z>.

If the input text is the Perl 5 string "C<Z>",
the derivation is as follows:

    S -> A Y        (Rule 0)
      -> A Z      (Y produces Z, by Rule 6)
      -> B C Z    (A produces B C, by Rule 2)
      -> B Z      (C produces the empty string, by Rule 4)
      -> Z        (B produces the empty string, by Rule 3)

The parse tree can be described as follows:

    Node 0 (root): S (2 children, nodes 1 and 4)
        Node 1: A (2 children, nodes 2 and 3)
	    Node 2: B (matches empty string)
	    Node 3: C (matches empty string)
	Node 4: Y (1 child, node 5)
	    Node 5: Z (terminal node)

Here's a table showing, for each node, its lhs symbol,
the sentence it derives, and
its value.

                      Symbol      Sentence     Value
                                  Derived

    Node 0:              S         Z           "A is missing, but Zorro is here"
        Node 1:          A         empty       "A is missing"
	    Node 2:      B         empty       No value
	    Node 3:      C         empty       No value
	Node 4:          Y         Z           "Zorro was here"
	    Node 5:      Z         Z           "Z"

In this derivation,
nodes 1, 2 and 3 derive the empty sentence.
None of them are the start node so that none of them count.

Nodes 0, 4 and 5 all derive the same non-empty sentence, C<Z>,
so they all count.
Node 0 is the start node, so it would have counted in any case.

Since node 5 is a terminal node, it's value comes from the lexer.
Where the lexing is done with a Perl 5 regex,
the value will be the Perl 5 string that the regex matched.
In this case it's the string "C<Z>".

Node 4 is not nulled,
so it is evaluated normally, using the rule it represents.
That is rule 6.
The action for rule 6 returns "C<Zorro was here>", so that
is the value of node 4.
Node 4 has a child node, node 5, but rule 6's action pays no
attention to child values.
The action for each rule is free to use or not use child values.

Nodes 1, 2 and 3 don't count and will all remain unevaluated.
The only rule left to be evaluated
is node 0, the start node.
It is not nulled, so
its value is calculated using the action for the rule it
represents (rule 0).

Rule 0's action uses the values of its child nodes.
There are two child nodes and their values are
elements 0 and 1 in the C<@$_> array of the action.
The child value represented by the symbol C<Y>,
C<< $_->[1] >>, comes from node 4.
From the table above, we can see that that value was
"C<Zorro was here>".

The first child value is represented by the symbol C<A>,
which is nulled.
For nulled symbols, we must use the null symbol value.
Null symbol values for each symbol can be explicitly set
by specifying an rule action for an empty rule with that symbol
as its lhs.
For symbol C<A>,
this was done in Rule 1.
Rule 1's action evaluates to the Perl 5 string
"C<A is missing>".

Even though rule 1's action plays a role in calculating the value of this parse,
rule 1 is not actually used in the derivation.
No node in the derivation represents rule 1.
Rule 1 is used because it defines the null symbol value for
the symbol C<A>.

Now that we have both child values, we can use rule 0's action
to calculate the value of node 0.
That value is "C<A is missing, but Zorro was here>",
This becomes the value of C<S>, rule 0's left hand side symbol and
the start symbol of the grammar.
A parse has the value of its start symbol,
so "C<A is missing, but Zorro was here>" is also
the value of the parse.

=head1 METHODS

=head2 new

    my $evaler = new Parse::Marpa::Evaluator($recce);

Z<>

    my $evaler = new Parse::Marpa::Evaluator($recce, $location);

Creates an evaluator object.
On success, returns the evaluator object.
Failures are thrown as exceptions.

The first, required, argument is a recognizer object.
The second, optional, argument
will be used as the number of the earleme at which to end parsing.
If there is no second argument, parsing ends at the default end
of parsing, which was set in the recognizer.

=head2 next

    my $value = $evaler->value();

Iterates the evaluator object, returning a reference to the value of the next parse.
If there are no more parses, returns undefined.
Successful parses may evaluate to a Perl 5 undefined,
which the C<next> method will return as a reference to an undefined.
Failures are thrown as exceptions.

Parses are iterated in postorder.
If a symbol can both match a token and derive a rule,
the token match takes priority.
Other alternatives are taken in implementation dependent order.
When the order is important, it
may be manipulated by assigning priorities to the rules and
terminals.

A failed parse does not always show up as an exhausted parse in the recognizer.
Just because the recognizer was active when it was used to create
the evaluator, does not mean that the input matches the grammar.
If it does not match, there will be no parses and the C<next> method will
return undefined the first time it is called.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 LICENSE AND COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5.10.0.

=cut
