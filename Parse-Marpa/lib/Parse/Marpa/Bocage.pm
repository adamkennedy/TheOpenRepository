package Parse::Marpa::Internal::Bocage;
use 5.010_000;

use warnings;
## no critic
no warnings "recursion";
## use critic
use strict;
use integer;

# The bocage is Marpa's structure for keeping multiple parses.
# "Parse forests" are conventional for this, but Marpa's
# parses can be cyclical, so the structure must contain
# not just parse trees, but parse graphs.  I also restrict
# the and-nodes to be binary.  So it's not really a parse
# forest.  I call it a "parse bocage".  Bocages are
# the hedgerow forests of Brittany
# and Normandy, deliberately cultivated for centuries
# to be as tangled as possible in order to act
# as obstacles to wandering cattle and armies.

# A parse bocage is a list of or-nodes, whose child
# and-nodes must be (at most) binary.
# I keep the and-nodes binary, because they emerge that way
# from the Aycock-Horspool Earley items, they store the parses
# efficiently, and they are easy for doing tree
# traversals.

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

package Parse::Marpa::Internal::Or_Node;

use constant NAME => 0;
use constant AND_NODES => 1;

package Parse::Marpa::Internal::Tree_Node;

use constant OR_NODE     => 0;
use constant CHOICE      => 1;
use constant PREDECESSOR => 2;
use constant CAUSE       => 3;
use constant SUCCESSOR   => 4;
use constant EFFECT      => 5;

package Parse::Marpa::Internal::Bocage;

use constant RECOGNIZER  => 0;
use constant PARSE_COUNT => 1;    # number of parses in an ambiguous parse
use constant OR_NODES    => 2;
use constant TREE        => 3;    # current evaluation tree


use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

sub Parse::Marpa::Bocage::new {
    my $class         = shift;
    my $recognizer    = shift;
    my $parse_set_arg = shift;
    my $self          = bless [], $class;

    my $recognizer_class = ref $recognizer;
    my $right_class      = 'Parse::Marpa::Recognizer';
    croak(
        "Don't parse argument is class: $recognizer_class; should be: $right_class"
    ) unless $recognizer_class eq $right_class;

    # croak("Recognizer already in use by bocage")
    # if
    # defined $recognizer->[Parse::Marpa::Internal::Recognizer::BOCAGE];

    # weaken( $recognizer->[Parse::Marpa::Internal::Recognizer::BOCAGE] =
    # $self );

    my ( $grammar, $earley_sets, ) = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
    ];

    ## no critic ( Variables::ProhibitPackageVars )
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    ## use critic

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    my $trace_iteration_changes;

    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_iteration_changes = $grammar
            ->[Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES];
    }

    local ($Data::Dumper::Terse) = 1;

    my $online = $grammar->[Parse::Marpa::Internal::Grammar::ONLINE];
    if ( not $online ) {
        Parse::Marpa::Recognizer::end_input($recognizer);
    }
    my $default_parse_set =
        $recognizer->[Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET];

    $self->[Parse::Marpa::Internal::Bocage::PARSE_COUNT] = 0;
    $self->[Parse::Marpa::Internal::Bocage::OR_NODES] = [];

    my $current_parse_set = $parse_set_arg // $default_parse_set;

    # Look for the start item and start rule
    my $earley_set = $earley_sets->[$current_parse_set];

    my $start_item;
    my $start_rule;
    my $start_state;

    EARLEY_ITEM: for my $item ( @{$earley_set} ) {
        $start_state =
            $item->[Parse::Marpa::Internal::Earley_item::STATE];
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

    $self->[Parse::Marpa::Internal::Bocage::RECOGNIZER] = $recognizer;

    my $start_symbol = $start_rule->[Parse::Marpa::Internal::Rule::LHS];
    my ( $nulling, $null_value ) = @{$start_symbol}[
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_VALUE
    ];

    # deal with a null parse as a special case
    if ($nulling) {
        my $and_node = [];
        $and_node->[Parse::Marpa::Internal::And_Node::VALUE_REF] =
            \($start_symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]);
        $and_node->[Parse::Marpa::Internal::And_Node::CLOSURE] =
            $start_symbol->[Parse::Marpa::Internal::Rule::CLOSURE];

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
	$start_sapling->[Parse::Marpa::Internal::Sapling::NAME]   = $name;
    }
    $start_sapling->[Parse::Marpa::Internal::Sapling::ITEM]   = $start_item;
    $start_sapling->[Parse::Marpa::Internal::Sapling::SYMBOL] = $start_symbol;
    push @saplings, $start_sapling;

    my $i = 0;
    SAPLING: while (1) {

        my (
	    $sapling_name,
	    $item, $symbol, $rule, $position
	) = @{ $saplings[ $i++ ] }[
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
        my @rule_data;

        # If we have a rule and a position, get the current symbol
        if ( defined $position ) {

            my $symbol =
                $rule->[Parse::Marpa::Internal::Rule::RHS]->[$position];
            push @rule_data, [ $rule, $position, $symbol ];

        }
        else { # if not defined $position

            my $lhs_id = $symbol->[Parse::Marpa::Internal::Symbol::ID];
	    my $state = $item->[Parse::Marpa::Internal::Earley_item::STATE];
            for my $rule (
                @{  $state->[Parse::Marpa::Internal::QDFA::COMPLETE_RULES]
                        ->[$lhs_id];
                }
                )
            {

                my $rhs     = $rule->[Parse::Marpa::Internal::Rule::RHS];
                my $closure = $rule->[Parse::Marpa::Internal::Rule::CLOSURE];
                my $last_position = $#{$rhs};
                push @rule_data,
		    [ $rule, $last_position, $rhs->[$last_position], $closure ];

            }    # for my $rule

        } # not defined $position

        my @and_nodes;

        my $item_name = $item->[Parse::Marpa::Internal::Earley_item::NAME];

        RULE: for my $rule_data (@rule_data) {

            my ( $rule, $position, $symbol, $closure ) = @{$rule_data};

            my $rule_id = $rule->[Parse::Marpa::Internal::Rule::ID];

            my @work_list;
            if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLING] ) {
                @work_list = (
                    [   $item,
                        undef,
                        \($symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE])
                    ]
                );
            }
            else {
                @work_list = (
                    (map { [ $_->[0], undef, \($_->[1]) ] } @{
			$item
			    ->[Parse::Marpa::Internal::Earley_item::TOKENS
			    ]
			}
                    ),
		    (map { [ $_->[0], $_->[1] ] } @{
			    $item ->[Parse::Marpa::Internal::Earley_item::LINKS]
			}
		    )
		);
            }

            for my $work_item (@work_list) {

                my ( $predecessor, $cause, $value_ref ) = @{$work_item};

                my $predecessor_name;

                if ( $position > 0 ) {

                    $predecessor_name
			= $predecessor->[Parse::Marpa::Internal::Earley_item::NAME]
                        . 'R' . $rule_id . q{:} . ( $position - 1 );

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
				$predecessor_name,
				$rule, $position - 1, $predecessor,
			    );

                        push @saplings, $sapling;

                    }    # $predecessor_name ~~ %or_node_by_name

                }    # if position > 0

                my $cause_name;

                if ( defined $cause ) {

                    my $symbol_id =
                        $symbol->[Parse::Marpa::Internal::Symbol::ID];

                    $cause_name
			= $cause->[Parse::Marpa::Internal::Earley_item::NAME]
			. 'L' . $symbol_id;

                    unless ( $cause_name ~~ %or_node_by_name ) {

                        $or_node_by_name{$cause_name} = [];

                        my $sapling = [];
                        @{$sapling}[
                            Parse::Marpa::Internal::Sapling::NAME,
                            Parse::Marpa::Internal::Sapling::SYMBOL,
                            Parse::Marpa::Internal::Sapling::ITEM,
                            ]
                            = ( $cause_name, $symbol, $cause );

                        push @saplings, $sapling;

                    }    # $cause_name ~~ %or_node_by_name

                }    # if cause

                my $and_node = [];
                @{$and_node}[
                    Parse::Marpa::Internal::And_Node::PREDECESSOR,
                    Parse::Marpa::Internal::And_Node::CAUSE,
                    Parse::Marpa::Internal::And_Node::VALUE_REF,
                    Parse::Marpa::Internal::And_Node::CLOSURE,
                    ]
                    = ( $predecessor_name, $cause_name, $value_ref, $closure );

                push @and_nodes, $and_node;

            }    # for work_item

        }    # RULE

	my $or_node = [];
	$or_node->[Parse::Marpa::Internal::Or_Node::NAME] = $sapling_name;
	$or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES] = \@and_nodes;
	push @{$self->[OR_NODES]}, $or_node;
	$or_node_by_name{$sapling_name} = $or_node;

    }    # SAPLING

    # resolve links in the bocage
    for my $and_node (
        map { @{ $_->[Parse::Marpa::Internal::Or_Node::AND_NODES] } }
        @{$self->[OR_NODES]} )
    {
        FIELD: for my $field (
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

sub Parse::Marpa::Bocage::show_bocage {
     my $bocage = shift;
     my $text = q{};

     for my $or_node (@{$bocage->[OR_NODES]}) {

	 my $lhs = $or_node->[Parse::Marpa::Internal::Or_Node::NAME];

         for my $and_node (@{$or_node->[Parse::Marpa::Internal::Or_Node::AND_NODES]}) {

	     my @rhs = ();

	     my $predecessor = $and_node->[Parse::Marpa::Internal::And_Node::PREDECESSOR];
	     if ($predecessor) {
	         push @rhs, $predecessor->[Parse::Marpa::Internal::Or_Node::NAME];
	     } # predecessor

	     my $cause = $and_node->[Parse::Marpa::Internal::And_Node::CAUSE];
	     if ($cause) {
	         push @rhs, $cause->[Parse::Marpa::Internal::Or_Node::NAME];
	     } # cause

	     my $value_ref = $and_node->[Parse::Marpa::Internal::And_Node::VALUE_REF];
	     if (defined $value_ref) {
		 my $value_as_string = Dumper(${$value_ref});
	         chomp $value_as_string;
	         push @rhs, $value_as_string;
	     } # value

	     $text .= $lhs . ' ::= ' . join(q{ }, @rhs) . "\n";

	 } # for my $and_node;

     } # for my $or_node

     return $text;
}

sub test_closure {
    my $tree_node = shift;

    my @tree_nodes = ($tree_node);

    while (
	$tree_node
	= $tree_node->[Parse::Marpa::Internal::Tree_Node::PREDECESSOR]
    ) {
        push @tree_nodes, $tree_node;
    }  # while ($tree_node)

    my @value;

    TREE_NODE: for my $tree_node (reverse @tree_nodes) {

        my $cause = $tree_node
	    ->[Parse::Marpa::Internal::Tree_Node::CAUSE];

	if ($cause) {
	    push @value, test_closure($cause);
	    next TREE_NODE;
	} # $cause

	my ($or_node, $choice) = @{$tree_node}[
	    Parse::Marpa::Internal::Tree_Node::OR_NODE,
	    Parse::Marpa::Internal::Tree_Node::CHOICE,
	];

	my $value_ref = $or_node
	    ->[Parse::Marpa::Internal::Or_Node::AND_NODES]
	    ->[$choice]
	    ->[Parse::Marpa::Internal::And_Node::VALUE_REF];
	push @value, ${$value_ref};

    }  # TREE_NODE

    return $value[0] if @value <= 1;
    return '(' . (join q{;}, @value) . ')';

}

sub Parse::Marpa::Bocage::next {
    my $evaler     = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Bocage::RECOGNIZER];

    croak('No parse supplied') unless defined $evaler;
    my $evaler_class = ref $evaler;
    my $right_class  = 'Parse::Marpa::Bocage';
    croak(
        "Don't parse argument is class: $evaler_class; should be: $right_class"
    ) unless $evaler_class eq $right_class;

    my ( $grammar, ) = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
    ];

    ## no critic ( Variables::ProhibitPackageVars )
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    ## use critic

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    my $trace_iteration_changes;
    my $trace_iteration_searches;
    if ($tracing) {
        $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_iteration_changes = $grammar
            ->[Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES];
        $trace_iteration_searches = $grammar
            ->[Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES];
    }

    local ($Data::Dumper::Terse) = 1;

    my $max_parses = $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES];
    my ($parse_count, $bocage, $tree)
	= @{$evaler}[
	    Parse::Marpa::Internal::Bocage::PARSE_COUNT,
	    Parse::Marpa::Internal::Bocage::OR_NODES,
	    Parse::Marpa::Internal::Bocage::TREE,
	];
    $evaler->[Parse::Marpa::Internal::Bocage::PARSE_COUNT]++;

    TREE: while (1) {

	croak('Multiple parses not yet implemented') if defined $tree;

	my $initial_ur_node;

	if (not defined $initial_ur_node) {

	     $evaler->[Parse::Marpa::Internal::Bocage::TREE]
		 = $tree = [];
	     $initial_ur_node = [$bocage->[0]];

	}

	# A preorder traversal, to build the tree
	# Start with the first or-node of the bocage.
	# The code below assumes the or-node is the first field of the tree node.
	my @traversal_stack = ($initial_ur_node);
	OR_NODE: while (@traversal_stack) {

	    my $tree_ur_node = pop @traversal_stack;
	    my ($predecessor_or_node, $cause_or_node)
		= @{$tree_ur_node
		    ->[Parse::Marpa::Internal::Tree_Node::OR_NODE]
		    ->[Parse::Marpa::Internal::Or_Node::AND_NODES]
		    ->[0]};

	    my $predecessor_tree_node;
	    if (defined $predecessor_or_node) {
		$predecessor_tree_node->[Parse::Marpa::Internal::Tree_Node::OR_NODE]
		    = $predecessor_or_node;
		weaken(
		    $predecessor_tree_node->[Parse::Marpa::Internal::Tree_Node::SUCCESSOR]
			= $tree_ur_node
		);
	    }

	    my $cause_tree_node;
	    if (defined $cause_or_node) {
		$cause_tree_node->[Parse::Marpa::Internal::Tree_Node::OR_NODE]
		    = $cause_or_node;
		weaken(
		    $cause_tree_node->[Parse::Marpa::Internal::Tree_Node::EFFECT]
			= $tree_ur_node
		);
	    }

	    @{$tree_ur_node}[
		Parse::Marpa::Internal::Tree_Node::CHOICE,
		Parse::Marpa::Internal::Tree_Node::PREDECESSOR,
		Parse::Marpa::Internal::Tree_Node::CAUSE,
	    ] = (
		0,
		$predecessor_tree_node,
		$cause_tree_node,
	    );
	    push @{$tree}, $tree_ur_node;
	    push @traversal_stack, grep { defined $_ } ($cause_tree_node, $predecessor_tree_node);

	} # OR_NODE

	return \test_closure($tree->[0]);

    } # TREE

    return;

}

1;

__END__

=pod

=head1 NAME

Parse::Marpa::Bocage - Marpa Parse Bocage Objects

=head1 SYNOPSIS

    my $grammar = new Parse::Marpa::Grammar({ mdl_source => \$mdl });
    my $recce = new Parse::Marpa::Recognizer({ grammar => $grammar });
    my $fail_offset = $recce->text(\("2-0*3+1"));
    croak("Parse failed at offset $fail_offset") if $fail_offset >= 0;

    my $evaler = new Parse::Marpa::Bocage($recce);

    for (my $i = 0; defined(my $value = $evaler->tree()); $i++) {
        croak("Ambiguous parse has extra value: ", $$value, "\n")
	    if $i > $expected;
	say "Ambiguous Equation Value $i: ", $$value;
    }

=head1 DESCRIPTION

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 LICENSE AND COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
