use 5.010_000;

use warnings;
no warnings "recursion";
use strict;
use integer;

package Parse::Marpa::Internal::Shoot;

use constant ITEM        => 0;
use constant RULE        => 1;
use constant POSITION    => 2;
use constant SYMBOL      => 3;

package Parse::Marpa::Internal::Branch;

use constant PREDECESSOR => 0;
use constant CAUSE       => 1;
use constant VALUE       => 2;
use constant CLOSURE     => 3;

package Parse::Marpa::Internal::Tangle;

use constant BRANCHES => 0;

package Parse::Marpa::Internal::Bocage;

use constant RECOGNIZER  => 0;
use constant PARSE_COUNT => 1;    # number of parses in an ambiguous parse

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

sub Parse::Marpa::Bocage::new {
    my $class         = shift;
    my $recognizer    = shift;
    my $parse_set_arg = shift;
    my $self          = bless [], $class;

    my $recognizer_class = ref $recognizer;
    my $right_class      = "Parse::Marpa::Recognizer";
    croak(
        "Don't parse argument is class: $recognizer_class; should be: $right_class"
    ) unless $recognizer_class eq $right_class;

    croak("Recognizer already in use by bocage")
        if
        defined $recognizer->[Parse::Marpa::Internal::Recognizer::BOCAGE];

    weaken( $recognizer->[Parse::Marpa::Internal::Recognizer::BOCAGE] =
            $self );

    my ( $grammar, $earley_sets, ) = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
    ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
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

    $self->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT] = 0;

    my $current_parse_set = $parse_set_arg // $default_parse_set;

    # Look for the start item and start rule
    my $earley_set = $earley_sets->[$current_parse_set];

    # The start rule, if not nulling, must be a pure links rule
    # (no tokens) because I don't allow tokens to be recognized
    # for the start symbol

    my $start_item;
    my $start_rule;
    my $start_state;

    # mark start items with LHS?
    EARLEY_ITEM: for ( my $ix = 0; $ix <= $#$earley_set; $ix++ ) {
        $start_item = $earley_set->[$ix];
        $start_state = $start_item->[Parse::Marpa::Internal::Earley_item::STATE];
        $start_rule = $start_state->[Parse::Marpa::Internal::QDFA::START_RULE];
        last EARLEY_ITEM if $start_rule;
    }

    return unless $start_rule;

    @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::START_ITEM,
        Parse::Marpa::Internal::Recognizer::CURRENT_PARSE_SET,
        ]
        = ( $start_item, $current_parse_set );

    $self->[Parse::Marpa::Internal::Bocage::RECOGNIZER] = $recognizer;

    # finish_evaluation($self);

    # $self;

    my $start_symbol = $start_rule->[Parse::Marpa::Internal::Rule::LHS];
    my ( $nulling, $null_value ) = @{$start_symbol}[
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_VALUE
    ];

    # deal with a null parse as a special case
    if ($nulling) {
	my $branch = [];
	$branch->[Parse::Marpa::Internal::Branch::VALUE]
	    = $start_symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE];
	$branch->[Parse::Marpa::Internal::Branch::CLOSURE]
	    = $start_symbol->[Parse::Marpa::Internal::Rule::CLOSURE];

	my $tangle = [];
	$tangle->[Parse::Marpa::Internal::Tangle::BRANCHES] = [ $branch ];

	$self->[TANGLES] = [ $tangle ];

	return $self;

    } # if $nulling

    my @shoots;
    my $start_shoot = [];
    $start_shoot->[Parse::Marpa::Internal::Shoot::ITEM] = $start_item;
    $start_shoot->[Parse::Marpa::Internal::Shoot::SYMBOL] = $start_symbol;
    push(@shoots, $start_shoot);

    my $i = 0;
    SHOOT: for (;;) {
        
	my ($item, $symbol, $rule, $position) = @{$shoots[$i++]}[
	     Parse::Marpa::Internal::Shoot::ITEM,
	     Parse::Marpa::Internal::Shoot::SYMBOL,
	     Parse::Marpa::Internal::Shoot::RULE,
	     Parse::Marpa::Internal::Shoot::POSITION,
	];

	last SHOOT unless defined $item;

	# If we don't have a current rule, we need to get one,
	# or more,
	# and deduce the position and a new symbol from them.
	my @rule_data;
	 
	# If we have a rule and a position, get the current symbol
	if (defined $position) {

	    my $symbol
		= $rule->[Parse::Marpa::Internal::Rule::RHS]
		    ->[$position];
	    push(@rule_data, [$rule, $position, $symbol]);

	} else {

	    my $lhs_id = $symbol->[Parse::Marpa::Internal::Symbol::ID];
	    for my $rule (@{
	        $item
		   ->[Parse::Marpa::Internal::QDFA::COMPLETE_RULES]
		   ->[$lhs_id];
	    }) {
	        
		my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];
		my $closure = $rule->[Parse::Marpa::Internal::Rule::CLOSURE];
		my $last_position = $#$rhs;
		push(@rule_data,
		     [ $rule, $last_position, $rhs->[$last_position], $closure ]);

	    } # for my $rule

	} # if defined $position

	my @branches;

	RULE: for my $rule_data (@rule_data) {

	    my ($rule, $position, $symbol, $closure) = @$rule_data;

	    my $rule_id = $rule->[Parse::Marpa::Internal::Rule::ID];

	    if ($symbol->[Parse::Marpa::Internal::Symbol::NULLING]) {
	        
		my $predecessor_name;

		if ($position > 0) {

		    $predecessor_name
			= $item_name . 'R' . $rule_id . ':' . ($position - 1);

		    unless ($predecessor_name ~~ %shoot_by_name) {

		        $shoot_by_name{$predecessor_name} = [];

			my $shoot = [];
			@{$shoot}[
			     Parse::Marpa::Internal::Shoot::RULE,
			     Parse::Marpa::Internal::Shoot::POSITION,
			     Parse::Marpa::Internal::Shoot::ITEm,
			] = (
			   $rule, $position-1, $item
			);

			push(@shoot, $shoot);

		    } # $predecessor_name ~~ %shoot_by_name

		} # if position > 0

		my $value = $symbol->[ Parse::Marpa::Internal::Symbol::NULL_VALUE ];

		my $branch = [];
		@{$branch}[
		    Parse::Marpa::Internal::Branch::PREDECESSOR,
		    Parse::Marpa::Internal::Branch::VALUE,
		    Parse::Marpa::Internal::Branch::CLOSURE,
		] = (
		    $predecessor_name,
		    $value,
		    $closure
		);

		push(@branch, $branch);

	    } # if nulling symbol

	} # RULE

    } # SHOOT

    # resolve links in the bocage

    croak("to here");

    $self;

}

# Undocumented.  It's main purpose was to allow the user to differentiate
# between an unevaluated node and a node whose value was a Perl 5 undefined.
sub Parse::Marpa::Evaluator::value {
    my $evaler     = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    croak("Not yet converted");
    my $start_item =
        $recognizer->[Parse::Marpa::Internal::Recognizer::START_ITEM];
    return unless defined $start_item;
    my $value_ref = $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];

    # croak("No value defined") unless defined $value_ref;
    return $value_ref;
}

sub Parse::Marpa::Evaluator::tree {
    my $evaler     = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    croak("No parse supplied") unless defined $evaler;
    my $evaler_class = ref $evaler;
    my $right_class  = "Parse::Marpa::Evaluator";
    croak(
        "Don't parse argument is class: $evaler_class; should be: $right_class"
    ) unless $evaler_class eq $right_class;

    my ( $grammar, $start_item, $current_parse_set, ) = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::START_ITEM,
        Parse::Marpa::Internal::Recognizer::CURRENT_PARSE_SET,
    ];

    # TODO: Is this check enough be sure that this is an evaluated parse?
    croak("Parse not initialized: no start item") unless defined $start_item;

    my $max_parses = $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES];
    my $parse_count =
        $evaler->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT];
    if ( $max_parses > 0 && $parse_count > $max_parses ) {
        croak("Maximum parse count ($max_parses) exceeded");
    }

    if ( $parse_count <= 0 ) {
        $evaler->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT] = 1;

        # Allow semipredication
        my $start_value =
            $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
        return \(undef) if not defined $start_value;
        return $start_value;
    }

    $evaler->[Parse::Marpa::Internal::Evaluator::PARSE_COUNT]++;

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
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

}

1;

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

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
