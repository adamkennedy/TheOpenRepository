package Marpa::Evaluator;

use 5.010;
use warnings;
no warnings qw(recursion qw);
use strict;
use integer;

package Marpa::Internal::Evaluator;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use Scalar::Util;
use List::Util;
use English qw( -no_match_vars );
use Data::Dumper;
use Marpa::Internal;

# Returns false if no parse
sub Marpa::Recognizer::value {
    my ( $class, @arg_hashes ) = @_;

    ### Constructing new evaluator
    my $self = bless [], $class;
    local $Marpa::Internal::EVAL_INSTANCE = $self;

    my $recce;
    my $parse_set_arg;

    for my $arg_hash (@arg_hashes) {

        $parse_set_arg = $arg_hash->{end};
        delete $arg_hash->{end};

        $self->[Marpa::Internal::Evaluator::EXPLICIT_CLOSURES] =
            $arg_hash->{closures} // {};
        delete $arg_hash->{closures};

    } ## end for my $arg_hash (@arg_hashes)

    local $Marpa::Internal::TRACE_FH =
        $recce->[Marpa::Internal::Recognizer::TRACE_FILE_HANDLE];

    my $grammar = $recce->[Marpa::Internal::Recognizer::GRAMMAR];
    my $action_object_class =
        $grammar->[Marpa::Internal::Grammar::ACTION_OBJECT];
    my $earley_sets = $recce->[Marpa::Internal::Recognizer::EARLEY_SETS];

    my $furthest_earleme =
        $recce->[Marpa::Internal::Recognizer::FURTHEST_EARLEME];
    my $last_completed_earleme =
        $recce->[Marpa::Internal::Recognizer::LAST_COMPLETED_EARLEME];
    Marpa::exception(
        "Attempt to evaluate incompletely recognized parse:\n",
        "  Last token ends at location $furthest_earleme\n",
        "  Recognition done only as far as location $last_completed_earleme\n"
    ) if $furthest_earleme > $last_completed_earleme;

    # default settings
    $self->[Marpa::Internal::Recognizer::TRACE_VALUES]  = 0;

    $self->set(@arg_hashes);

    my $rules   = $grammar->[Marpa::Internal::Grammar::RULES];
    my $symbols = $grammar->[Marpa::Internal::Grammar::SYMBOLS];

    my $trace_tasks = $self->[Marpa::Internal::Recognizer::TRACE_TASKS];
    my $trace_evaluation =
        $self->[Marpa::Internal::Recognizer::TRACE_EVALUATION];

    my $and_nodes = [];

    my $current_parse_set = $parse_set_arg
        // $recce->[Marpa::Internal::Recognizer::FURTHEST_EARLEME];

    # Look for the start item and start rule
    my $earley_set = $earley_sets->[$current_parse_set];

    my $start_item;
    my $start_rule;
    my $start_state;

    EARLEY_ITEM: for my $item ( @{$earley_set} ) {
        $start_state = $item->[Marpa::Internal::Earley_Item::STATE];
        $start_rule  = $start_state->[Marpa::Internal::QDFA::START_RULE];
        next EARLEY_ITEM if not $start_rule;
        $start_item = $item;
        last EARLEY_ITEM;
    } ## end for my $item ( @{$earley_set} )

    return if not $start_rule;

    my $start_rule_id = $start_rule->[Marpa::Internal::Rule::ID];

    state $parse_number = 0;
    my $null_values;
    $null_values = set_null_values($self);

    # Set up rank closures by symbol
    my $ranking_closures_by_symbol = [];
    $#{$ranking_closures_by_symbol} = $#{$symbols};
    SYMBOL: for my $symbol ( @{$symbols} ) {
        my $ranking_action =
            $symbol->[Marpa::Internal::Symbol::RANKING_ACTION];
        next SYMBOL if not defined $ranking_action;
        my $ranking_closure =
            Marpa::Internal::Evaluator::resolve_semantics( $self,
            $ranking_action );
        Marpa::exception("Ranking closure '$ranking_action' not found")
            if not defined $ranking_closure;
        $ranking_closures_by_symbol->[ $symbol->[Marpa::Internal::Symbol::ID]
        ] = $ranking_closure;
    } ## end for my $symbol ( @{$symbols} )

    my $evaluator_rules =
        set_actions($self);

    # Get closure used in ranking, by rule
    my $ranking_closures_by_rule = [];
    $#{$ranking_closures_by_rule} = $#{$rules};
    RULE: for my $rule ( @{$rules} ) {
        next RULE
            if not my $ranking_action =
                $rule->[Marpa::Internal::Rule::RANKING_ACTION];

        # If the RHS is empty ...
        if ( not scalar @{ $rule->[Marpa::Internal::Rule::RHS] } ) {
            my $ranking_closure =
                Marpa::Internal::Evaluator::resolve_semantics( $self,
                $ranking_action );
            Marpa::exception("Ranking closure '$ranking_action' not found")
                if not defined $ranking_closure;

            $ranking_closures_by_symbol->[ $rule->[Marpa::Internal::Rule::LHS]
                ->[Marpa::Internal::Symbol::NULL_ALIAS]
                ->[Marpa::Internal::Symbol::ID] ] = $ranking_closure;
        } ## end if ( not scalar @{ $rule->[Marpa::Internal::Rule::RHS...]})

        next RULE if not $rule->[Marpa::Internal::Rule::USEFUL];
        my $ranking_closure =
            Marpa::Internal::Evaluator::resolve_semantics( $self,
            $ranking_action );
        Marpa::exception("Ranking closure '$ranking_action' not found")
            if not defined $ranking_closure;
        $ranking_closures_by_rule->[ $rule->[Marpa::Internal::Rule::ID] ] =
            $ranking_closure;
    } ## end for my $rule ( @{$rules} )

    my $action_object_constructor;

    if (defined(
            my $action_object =
                $grammar->[Marpa::Internal::Grammar::ACTION_OBJECT]
        )
        )
    {
        my $constructor_name = $action_object . q{::new};
        my $closure = resolve_semantics( $self, $constructor_name );
        Marpa::exception(qq{Could not find constructor "$constructor_name"})
            if not defined $closure;
	Marpa::exception(q{!!! need to call this before evaluation !!!});
        $action_object_constructor = $closure;
    } ## end if ( defined( my $action_object = $grammar->[...]))

    Marpa::exception(q{!!! What to do?  I won't handle cycles !!!});

    my $start_symbol = $start_rule->[Marpa::Internal::Rule::LHS];
    my ( $nulling, $symbol_id ) =
        @{$start_symbol}[ Marpa::Internal::Symbol::NULLING,
        Marpa::Internal::Symbol::ID, ];
    my $start_null_value = $null_values->[$symbol_id];

    # deal with a null parse as a special case
    if ($nulling) {

        my $or_node = [];
        $#{$or_node} = Marpa::Internal::Or_Node::LAST_FIELD;

        my $and_node = [];
        $#{$and_node} = Marpa::Internal::And_Node::LAST_FIELD;

        $or_node->[Marpa::Internal::Or_Node::CHILD_IDS]     = [0];
        $or_node->[Marpa::Internal::Or_Node::START_EARLEME] = 0;
        $or_node->[Marpa::Internal::Or_Node::END_EARLEME]   = 0;
        my $or_node_id = $or_node->[Marpa::Internal::Or_Node::ID] = 0;
        my $or_node_tag = $or_node->[Marpa::Internal::Or_Node::TAG] =
            $start_item->[Marpa::Internal::Earley_Item::NAME]
            . "o$or_node_id";

        $and_node->[Marpa::Internal::And_Node::VALUE_REF] =
            \$start_null_value;
        $and_node->[Marpa::Internal::And_Node::VALUE_OPS] =
            $evaluator_rules->[$start_rule_id];
        $and_node->[Marpa::Internal::And_Node::RULE_ID]  = $start_rule_id;
        $and_node->[Marpa::Internal::And_Node::POSITION] = -1;
        $and_node->[Marpa::Internal::And_Node::START_EARLEME] = 0;
        $and_node->[Marpa::Internal::And_Node::END_EARLEME]   = 0;
        $and_node->[Marpa::Internal::And_Node::PARENT_ID]     = 0;
        $and_node->[Marpa::Internal::And_Node::PARENT_CHOICE] = 0;

        my $and_node_id = $and_node->[Marpa::Internal::And_Node::ID] = 0;
        $and_node->[Marpa::Internal::And_Node::TAG] =
            $or_node_tag . "a$and_node_id";

        push @{$and_nodes}, $and_node;

        return $self;

    }    # if $nulling

    my @or_saplings;
    my %or_node_by_name;
    my $start_sapling = [];
    {
        my $start_name = $start_item->[Marpa::Internal::Earley_Item::NAME];
        my $start_symbol_id = $start_symbol->[Marpa::Internal::Symbol::ID];
        $start_name .= 'L' . $start_symbol_id;
        $start_sapling->[Marpa::Internal::Or_Sapling::NAME] = $start_name;
    }
    $start_sapling->[Marpa::Internal::Or_Sapling::ITEM] = $start_item;
    $start_sapling->[Marpa::Internal::Or_Sapling::CHILD_LHS_SYMBOL] =
        $start_symbol;
    push @or_saplings, $start_sapling;

    my $i = 0;
    OR_SAPLING: while (1) {

        my ( $sapling_name, $item, $child_lhs_symbol, $rule, $position ) =
            @{ $or_saplings[ $i++ ] }[
            Marpa::Internal::Or_Sapling::NAME,
            Marpa::Internal::Or_Sapling::ITEM,
            Marpa::Internal::Or_Sapling::CHILD_LHS_SYMBOL,
            Marpa::Internal::Or_Sapling::RULE,
            Marpa::Internal::Or_Sapling::POSITION,
            ];

        last OR_SAPLING if not defined $item;

        # If we don't have a current rule, we need to get one or
        # more rules, and deduce the position and a new symbol from
        # them.
        my @and_saplings;

        my $is_kernel_or_node = defined $position;

        if ($is_kernel_or_node) {

            # Kernel or-node: We have a rule and a position.
            # get the current symbol

            $position--;
            my $symbol = $rule->[Marpa::Internal::Rule::RHS]->[$position];
            push @and_saplings, [ $rule, $position, $symbol ];

        } ## end if ($is_kernel_or_node)
        else {

            # Closure or-node.

            my $child_lhs_id =
                $child_lhs_symbol->[Marpa::Internal::Symbol::ID];
            my $state = $item->[Marpa::Internal::Earley_Item::STATE];
            for my $rule (
                @{  $state->[Marpa::Internal::QDFA::COMPLETE_RULES]
                        ->[$child_lhs_id];
                }
                )
            {

                my $rhs = $rule->[Marpa::Internal::Rule::RHS];

                my $last_position = @{$rhs} - 1;
                push @and_saplings,
                    [
                    $rule,
                    $last_position,
                    $rhs->[$last_position],
                    $evaluator_rules->[ $rule->[Marpa::Internal::Rule::ID] ]
                    ];

            }    # for my $rule

        }    # closure or-node

        my $start_earleme = $item->[Marpa::Internal::Earley_Item::PARENT];
        my $end_earleme   = $item->[Marpa::Internal::Earley_Item::SET];

        my @child_and_nodes;

        my $item_name = $item->[Marpa::Internal::Earley_Item::NAME];

        for my $and_sapling (@and_saplings) {

            my ($sapling_rule, $sapling_position,
                $symbol,       $value_processing
            ) = @{$and_sapling};

            my $rule_id     = $sapling_rule->[Marpa::Internal::Rule::ID];
            my $rhs         = $sapling_rule->[Marpa::Internal::Rule::RHS];
            my $rule_length = @{$rhs};

            my @or_bud_list;
            if ( $symbol->[Marpa::Internal::Symbol::NULLING] ) {
                my $nulling_symbol_id =
                    $symbol->[Marpa::Internal::Symbol::ID];
                my $null_value = $null_values->[$nulling_symbol_id];
                @or_bud_list = ( [ $item, undef, $symbol, \$null_value, ] );
            } ## end if ( $symbol->[Marpa::Internal::Symbol::NULLING] )
            else {
                @or_bud_list = (
                    (   map { [ $_->[0], undef, @{$_}[ 1, 2 ] ] }
                            @{ $item->[Marpa::Internal::Earley_Item::TOKENS] }
                    ),
                    (   map { [ $_->[0], $_->[1] ] }
                            @{ $item->[Marpa::Internal::Earley_Item::LINKS] }
                    )
                );
            } ## end else [ if ( $symbol->[Marpa::Internal::Symbol::NULLING] ) ]

            for my $or_bud (@or_bud_list) {

                my ( $predecessor, $cause, $token, $value_ref ) = @{$or_bud};

                my $predecessor_name;

                if ( $sapling_position > 0 ) {

                    $predecessor_name =
                        $predecessor->[Marpa::Internal::Earley_Item::NAME]
                        . "R$rule_id:$sapling_position";

                    # We check that the predecessor has not already been
                    # processed so that cycles don't put us into a loop
                    if ( not $predecessor_name ~~ %or_node_by_name ) {

                        $or_node_by_name{$predecessor_name} = [];

                        my $sapling = [];
                        @{$sapling}[
                            Marpa::Internal::Or_Sapling::NAME,
                            Marpa::Internal::Or_Sapling::RULE,
                            Marpa::Internal::Or_Sapling::POSITION,
                            Marpa::Internal::Or_Sapling::ITEM,
                            ]
                            = (
                            $predecessor_name, $sapling_rule,
                            $sapling_position, $predecessor,
                            );

                        push @or_saplings, $sapling;

                    }    # $predecessor_name ~~ %or_node_by_name

                }    # if sapling_position > 0

                my $cause_name;

                if ( defined $cause ) {

                    my $cause_symbol_id =
                        $symbol->[Marpa::Internal::Symbol::ID];

                    $cause_name =
                          $cause->[Marpa::Internal::Earley_Item::NAME] . 'L'
                        . $cause_symbol_id;

                    # We check that the cause has not already been
                    # processed so that cycles don't put us into a loop
                    if ( not $cause_name ~~ %or_node_by_name ) {

                        $or_node_by_name{$cause_name} = [];

                        my $sapling = [];
                        @{$sapling}[
                            Marpa::Internal::Or_Sapling::NAME,
                            Marpa::Internal::Or_Sapling::CHILD_LHS_SYMBOL,
                            Marpa::Internal::Or_Sapling::ITEM,
                            ]
                            = ( $cause_name, $symbol, $cause, );

                        push @or_saplings, $sapling;

                    }    # $cause_name ~~ %or_node_by_name

                }    # if cause

                my $and_node = [];
                $#{$and_node} = Marpa::Internal::And_Node::LAST_FIELD;

                # At this point names stand in for the or-node ids,
                # which will eventually replace them in these fields
                $and_node->[Marpa::Internal::And_Node::PREDECESSOR_ID] =
                    $predecessor_name;
                $and_node->[Marpa::Internal::And_Node::CAUSE_ID] =
                    $cause_name;

                $and_node->[Marpa::Internal::And_Node::TOKEN] = $token;
                $and_node->[Marpa::Internal::And_Node::VALUE_REF] =
                    $value_ref;
                $and_node->[Marpa::Internal::And_Node::RULE_ID] = $rule_id;

                $and_node->[Marpa::Internal::And_Node::VALUE_OPS] =
                    $value_processing;

                $and_node->[Marpa::Internal::And_Node::POSITION] =
                    $sapling_position;
                $and_node->[Marpa::Internal::And_Node::START_EARLEME] =
                    $start_earleme;
                $and_node->[Marpa::Internal::And_Node::END_EARLEME] =
                    $end_earleme;
                my $id = $and_node->[Marpa::Internal::And_Node::ID] =
                    @{$and_nodes};
                Marpa::exception("Too many and-nodes for evaluator: $id")
                    if $id & ~(N_FORMAT_MAX);
                push @{$and_nodes}, $and_node;

                push @child_and_nodes, $and_node;

            }    # for my $or_bud

        }    # for my $and_sapling

    }    # OR_SAPLING

    my $and_node_counter = 0;

    # resolve links in the bocage
    for my $and_node ( @{$and_nodes} ) {
        my $and_node_id = $and_node->[Marpa::Internal::And_Node::ID];

        FIELD:
        for my $field (
            Marpa::Internal::And_Node::PREDECESSOR_ID,
            Marpa::Internal::And_Node::CAUSE_ID,
            )
        {
            my $name = $and_node->[$field];
            next FIELD if not defined $name;
            my $child_or_node = $or_node_by_name{$name};
            $and_node->[$field] =
                $child_or_node->[Marpa::Internal::Or_Node::ID];
            my $parent_ids =
                $child_or_node->[Marpa::Internal::Or_Node::PARENT_IDS];
            push @{$parent_ids}, $and_node_id;
        } ## end for my $field ( Marpa::Internal::And_Node::PREDECESSOR_ID...)

    } ## end for my $and_node ( @{$and_nodes} )

    my $action_object;

    if ($action_object_constructor) {
        my @warnings;
        my $eval_ok;
        DO_EVAL: {
            local $SIG{__WARN__} = sub {
                push @warnings, [ $_[0], ( caller 0 ) ];
            };

            $eval_ok = eval {
                $action_object =
                    $action_object_constructor->($action_object_class);
                1;
            };
        } ## end DO_EVAL:

        if ( not $eval_ok or @warnings ) {
            my $fatal_error = $EVAL_ERROR;
            Marpa::Internal::code_problems(
                {   fatal_error => $fatal_error,
                    grammar     => $grammar,
                    eval_ok     => $eval_ok,
                    warnings    => \@warnings,
                    where       => 'constructing action object',
                }
            );
        } ## end if ( not $eval_ok or @warnings )
    } ## end if ($action_object_constructor)

    $action_object //= {};

    Marpa::exception('Add call to evaluation here!!!');

    return $self;

}    # sub new

1;
