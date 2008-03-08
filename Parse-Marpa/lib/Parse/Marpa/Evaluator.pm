use 5.010_000;

use warnings;
no warnings "recursion";
use strict;
use integer;

package Parse::Marpa::Read_Only;

our $rule;

package Parse::Marpa::Internal::Evaluator;

use constant RECOGNIZER => 0;
use constant PARSE_COUNT => 1;   # number of parses in an ambiguous parse

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

sub clear_notations {
    my $evaler = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    my ($earley_set_list) = @{$evaler}[Parse::Marpa::Internal::Recognizer::EARLEY_SETS];
    for my $earley_set (@$earley_set_list) {
        for my $earley_item (@$earley_set) {
            @{$earley_item}[
                Parse::Marpa::Internal::Earley_item::POINTER,
                Parse::Marpa::Internal::Earley_item::RULES,
                Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                Parse::Marpa::Internal::Earley_item::VALUE,
                Parse::Marpa::Internal::Earley_item::PREDECESSOR,
                Parse::Marpa::Internal::Earley_item::SUCCESSOR,
                Parse::Marpa::Internal::Earley_item::EFFECT,
                Parse::Marpa::Internal::Earley_item::LHS,
                ]
                = ( undef, undef, 0, 0, 0, undef, undef, undef, undef, undef, );
        }
    }
}

sub clear_values {
    my $evaler = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    my ($earley_set_list) = @{$recognizer}[Parse::Marpa::Internal::Recognizer::EARLEY_SETS];
    for my $earley_set (@$earley_set_list) {
        for my $earley_item (@$earley_set) {
            $earley_item->[ Parse::Marpa::Internal::Earley_item::VALUE ] = undef;
        }
    }
}

# returns 1 if it starts OK, undef otherwise
sub Parse::Marpa::Evaluator::new {
    my $class = shift;
    my $recognizer    = shift;
    my $parse_set_arg = shift;
    my $self = bless [], $class;

    my $recognizer_class = ref $recognizer;
    my $right_class = "Parse::Marpa::Recognizer";
    croak(
        "Don't parse argument is class: $recognizer_class; should be: $right_class"
    ) unless $recognizer_class eq $right_class;

    croak("Recognizer already in use by evaluator")
        if defined $recognizer->[ Parse::Marpa::Internal::Recognizer::EVALUATOR ];
    weaken(
        $recognizer->[ Parse::Marpa::Internal::Recognizer::EVALUATOR ] = $self
    );

    my ($grammar,                 $earley_sets,
        )
        = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::EARLEY_SETS,
        ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_iteration_changes;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_iteration_changes = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ];
    }

    local ($Data::Dumper::Terse) = 1;

    my $online = $grammar->[ Parse::Marpa::Internal::Grammar::ONLINE ];
    if (not $online) {
         Parse::Marpa::Recognizer::end_input($recognizer);
    }
    my $default_parse_set = $recognizer->[ Parse::Marpa::Internal::Recognizer::DEFAULT_PARSE_SET ];

    $self->[ Parse::Marpa::Internal::Evaluator::PARSE_COUNT ] = 0;
    clear_notations($self);

    my $current_parse_set = $parse_set_arg // $default_parse_set;

    # Look for the start item and start rule
    my $earley_set = $earley_sets->[$current_parse_set];

    # The start rule, if not nulling, must be a pure links rule
    # (no tokens) because I don't allow tokens to be recognized
    # for the start symbol

    my $start_item;
    my $start_rule;

    # mark start items with LHS?
    EARLEY_ITEM: for ( my $ix = 0; $ix <= $#$earley_set; $ix++ ) {
        $start_item = $earley_set->[$ix];
        my $state = $start_item->[Parse::Marpa::Internal::Earley_item::STATE];
        $start_rule = $state->[Parse::Marpa::Internal::SDFA::START_RULE];
        last EARLEY_ITEM if $start_rule;
    }

    return unless $start_rule;

    @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::START_ITEM,
        Parse::Marpa::Internal::Recognizer::CURRENT_PARSE_SET,
        ]
        = ( $start_item, $current_parse_set );

     $self->[Parse::Marpa::Internal::Evaluator::RECOGNIZER] = $recognizer;

     finish_evaluation($self);

     $self;
}

sub finish_evaluation {
    my $evaler = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    # mark start items with LHS?
    my $start_item = $recognizer->[ Parse::Marpa::Internal::Recognizer::START_ITEM ];
    my $grammar = $recognizer->[ Parse::Marpa::Internal::Recognizer::GRAMMAR ];

    my $previous_value =
        $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    return 1 if $previous_value;

    my $state = $start_item->[Parse::Marpa::Internal::Earley_item::STATE];
    my $start_rule = $state->[Parse::Marpa::Internal::SDFA::START_RULE];

    my $lhs = $start_rule->[Parse::Marpa::Internal::Rule::LHS];
    my ( $nulling, $null_value ) = @{$lhs}[
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_VALUE
    ];

    my $tracing
        = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_iteration_changes;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_iteration_changes = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ];
    }

    if ($nulling) {
        @{$start_item}[
            Parse::Marpa::Internal::Earley_item::VALUE,
            Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
            Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
            Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
            Parse::Marpa::Internal::Earley_item::RULES,
            Parse::Marpa::Internal::Earley_item::LHS,
            ]
            = ( \$null_value, 0, 0, 0, [$start_rule], $lhs, );
        if ($tracing && $trace_iteration_changes) {
            print $trace_fh
                "Setting nulling start value of ",
                Parse::Marpa::brief_earley_item($start_item), ", ",
                $lhs->[Parse::Marpa::Internal::Symbol::NAME], " to ",
                Dumper($null_value);
        }
        return 1;
    }

    my $value = initialize_children( $start_item, $lhs );
    @{$start_item}[
        Parse::Marpa::Internal::Earley_item::VALUE,
        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
        Parse::Marpa::Internal::Earley_item::RULES,
        Parse::Marpa::Internal::Earley_item::LHS,
        ]
        = ( \$value, 0, 0, 0, [$start_rule], $lhs, );
    if ($tracing && $trace_iteration_changes) {
        print $trace_fh "Setting start value of ",
            Parse::Marpa::brief_earley_item($start_item), ", ",
            $lhs->[Parse::Marpa::Internal::Symbol::NAME], " to ",
            Dumper($value);
    }

    1;

}

sub initialize_children {
    my $item       = shift;
    my $lhs_symbol = shift;

    my $grammar = $Parse::Marpa::Internal::This::grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_evaluation_choices;
    my $trace_iteration_changes;
    my $trace_iteration_searches;
    my $trace_values;
 
    if ($tracing) {
        $trace_fh
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_evaluation_choices
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_EVALUATION_CHOICES ];
        $trace_iteration_changes
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ];
        $trace_iteration_searches
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ];
        $trace_values
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_VALUES ];
    }

    $item->[Parse::Marpa::Internal::Earley_item::LHS] = $lhs_symbol;
    my $lhs_symbol_id = $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID];

    my ( $state, $child_rule_choice ) = @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
    ];

    if ( not defined $child_rule_choice ) {
        $child_rule_choice = 0;
    }
    my $child_rules =
        $state->[Parse::Marpa::Internal::SDFA::COMPLETE_RULES]
        ->[$lhs_symbol_id];
    my $rule = $child_rules->[$child_rule_choice];
    if ( $trace_evaluation_choices and scalar @$child_rules > 1 )
    {
        my ( $set, $parent ) = @{$item}[
            Parse::Marpa::Internal::Earley_item::SET,
            Parse::Marpa::Internal::Earley_item::PARENT,
        ];
        say $trace_fh "Choose rule ", $child_rule_choice,
            " of ", ( scalar @$child_rules ), " at earlemes ", $parent, "-",
            $set, ": ", Parse::Marpa::brief_rule($rule);
        for ( my $ix = 0; $ix <= $#$child_rules; $ix++ ) {
            my $choice = $child_rules->[$ix];
            say $trace_fh
                "Rule choice $ix at $parent-$set: ",
                Parse::Marpa::brief_rule($choice);
        }
    }
    local ($Parse::Marpa::Read_Only::rule) = $rule;
    my ($rhs) = @{$rule}[Parse::Marpa::Internal::Rule::RHS];

    my $values = [];    # to store values in

    my @work_entries;

    CHILD:
    for ( my $child_number = $#$rhs; $child_number >= 0; $child_number-- ) {

        my $child_symbol = $rhs->[$child_number];
        my $nulling =
            $child_symbol->[Parse::Marpa::Internal::Symbol::NULLING];

        if ($nulling) {
            my $null_value
                = $child_symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE];
            $values->[$child_number] = $null_value;

            if ($trace_values) {
                my $value_description =
                    (not defined $null_value) ?  "undefined" : $null_value;
                say $trace_fh
                    "Using null value for ",
                    $child_symbol->[ Parse::Marpa::Internal::Symbol::NAME ],
                    ": ",
                    $value_description;
            }

            next CHILD;
        }

        my ( $tokens, $links, $previous_value, $previous_predecessor,
            $item_set, )
            = @{$item}[
            Parse::Marpa::Internal::Earley_item::TOKENS,
            Parse::Marpa::Internal::Earley_item::LINKS,
            Parse::Marpa::Internal::Earley_item::VALUE,
            Parse::Marpa::Internal::Earley_item::PREDECESSOR,
            Parse::Marpa::Internal::Earley_item::SET,
            ];

        if ( defined $previous_value ) {
            $values->[$child_number] = $$previous_value;
            $item = $previous_predecessor;

            if ($trace_values) {
                my $value_description =
                    (not defined $$previous_value) ? "undefined" :
                    $$previous_value;
                say $trace_fh
                    "Using previous value for ",
                    $child_symbol->[ Parse::Marpa::Internal::Symbol::NAME ],
                    ": ",
                    $value_description;
            }

            next CHILD;
        }

        unless ( defined $child_rules ) {
            $child_rules       = [];
            $child_rule_choice = 0;
        }

        if (@$tokens) {
            my ( $predecessor, $value ) = @{ $tokens->[0] };

            if ( $trace_evaluation_choices
                and scalar @$tokens > 1 )
            {
                my ( $set, $parent ) = @{$item}[
                    Parse::Marpa::Internal::Earley_item::SET,
                    Parse::Marpa::Internal::Earley_item::PARENT,
                ];
                say $trace_fh "Choose token 0 of ",
                    ( scalar @$tokens ), " at earlemes ", $parent, "-", $set,
                    ": ", show_token_choice( $tokens->[0] );
                for ( my $ix = 1; $ix <= $#$tokens; $ix++ ) {
                    my $choice = $tokens->[$ix];
                    say $trace_fh
                        "Alternative token choice $ix at $parent-$set: ",
                        show_token_choice($choice);
                }
            }

            @{$item}[
                Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                Parse::Marpa::Internal::Earley_item::RULES,
                Parse::Marpa::Internal::Earley_item::VALUE,
                Parse::Marpa::Internal::Earley_item::PREDECESSOR,
                Parse::Marpa::Internal::Earley_item::POINTER,
                ]
                = (
                0, 0, $child_rule_choice, $child_rules, \$value, $predecessor,
                $child_symbol,
                );
            if ($trace_iteration_changes) {
                my $predecessor_set =
                    $predecessor->[ Parse::Marpa::Internal::Earley_item::SET,
                    ];
                print $trace_fh
                    "Initializing token value of ",
                    Parse::Marpa::brief_earley_item($item), ", ",
                    $child_symbol->[Parse::Marpa::Internal::Symbol::NAME],
                    " at ", $predecessor_set, "-", $item_set, " to ",
                    Dumper($value);
            }
            $values->[$child_number] = $value;
            weaken(
                $predecessor->[Parse::Marpa::Internal::Earley_item::SUCCESSOR]
                    = $item );
            $item = $predecessor;
            next CHILD;
        }

        # We've eliminated nulling symbols and symbols caused by tokens,
        # so we have to have a symbol caused by a completion

        my ( $predecessor, $cause ) = @{ $links->[0] };
        weaken( $cause->[Parse::Marpa::Internal::Earley_item::EFFECT] =
                $item );

        if ( $trace_evaluation_choices
            and scalar @$links > 1 )
        {
            my ( $set, $parent ) = @{$item}[
                Parse::Marpa::Internal::Earley_item::SET,
                Parse::Marpa::Internal::Earley_item::PARENT,
            ];
            say $trace_fh "Choose link 0 of ",
                ( scalar @$links ), " at earlemes ", $parent, "-", $set, ": ",
                show_link_choice( $links->[0] );
            for ( my $ix = 1; $ix <= $#$links; $ix++ ) {
                my $choice = $links->[$ix];
                say $trace_fh
                    "Alternative link choice $ix at $parent-$set: ",
                    show_link_choice( $links->[$ix] );
            }
        }

        my $work_entry =
            [ $predecessor, $item, $child_number, $cause, $child_symbol, ];

        # for efficiency push (right-to-left evaluation) is the default
        push( @work_entries, $work_entry );

        @{$item}[
            Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
            Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
            Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
            Parse::Marpa::Internal::Earley_item::RULES,

            # Parse::Marpa::Internal::Earley_item::VALUE,
            Parse::Marpa::Internal::Earley_item::PREDECESSOR,
            Parse::Marpa::Internal::Earley_item::POINTER,
            ]
            = (
            0,                  0,
            $child_rule_choice, $child_rules,

            # \$value,
            $predecessor,
            $child_symbol,
            );

        weaken(
            $predecessor->[Parse::Marpa::Internal::Earley_item::SUCCESSOR] =
                $item );
        $item = $predecessor;

    }    # CHILD

    for my $work_entry (@work_entries) {
        my ( $predecessor_item, $effect_item, $rhs_index, $cause,
            $child_symbol, )
            = @$work_entry;
        my $value = $values->[$rhs_index] =
            initialize_children( $cause, $child_symbol );
        $effect_item->[Parse::Marpa::Internal::Earley_item::VALUE] = \$value;
        if ($trace_iteration_searches) {
            my $predecessor_set =
                $predecessor_item->[Parse::Marpa::Internal::Earley_item::SET];
            my $item_set =
                $effect_item->[Parse::Marpa::Internal::Earley_item::SET];
            print $trace_fh
                "Initializing caused value of ",
                Parse::Marpa::brief_earley_item($effect_item), ", ",
                $child_symbol->[Parse::Marpa::Internal::Symbol::NAME], " at ",
                $predecessor_set, "-", $item_set, " to ", Dumper($value);
        }
    }

    my $closure = $rule->[Parse::Marpa::Internal::Rule::CLOSURE];
    my @warnings;
    return $closure unless defined $closure;

    my $result;
    {
        my @warnings;
        local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
        $result = eval {
	    local($_) = $values;
	    $closure->()
	};
        my $fatal_error = $@;
        if ($fatal_error or @warnings) {
            Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                "computing value",
                "computing value for rule: "
                    . Parse::Marpa::brief_original_rule($rule),
                \($rule->[Parse::Marpa::Internal::Rule::ACTION])
            );
        }
    }

    if ($trace_values) {
        my $result_description =
            (not defined $result) ?  "undefined" : $result;
        say $trace_fh "Rule ", Parse::Marpa::brief_rule($rule), "; value: ", $result_description;
    }

    $result;

}

# Undocumented.  It's main purpose was to allow the user to differentiate 
# between an unevaluated node and a node whose value was a Perl 5 undefined.
sub Parse::Marpa::Evaluator::value {
    my $evaler = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    croak("Not yet converted");
    my $start_item = $recognizer->[Parse::Marpa::Internal::Recognizer::START_ITEM];
    return unless defined $start_item;
    my $value_ref = $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    # croak("No value defined") unless defined $value_ref;
    return $value_ref;
}

sub Parse::Marpa::Evaluator::next {
    my $evaler = shift;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    croak("No parse supplied") unless defined $evaler;
    my $evaler_class = ref $evaler;
    my $right_class = "Parse::Marpa::Evaluator";
    croak(
        "Don't parse argument is class: $evaler_class; should be: $right_class"
    ) unless $evaler_class eq $right_class;

    my ( $grammar, $start_item, $current_parse_set, )
        = @{$recognizer}[
        Parse::Marpa::Internal::Recognizer::GRAMMAR,
        Parse::Marpa::Internal::Recognizer::START_ITEM,
        Parse::Marpa::Internal::Recognizer::CURRENT_PARSE_SET,
        ];

    # TODO: Is this check enough be sure that this is an evaluated parse?
    croak("Parse not initialized: no start item") unless defined $start_item;

    my $max_parses = $grammar->[ Parse::Marpa::Internal::Grammar::MAX_PARSES ];
    my $parse_count = $evaler->[ Parse::Marpa::Internal::Evaluator::PARSE_COUNT ];
    if ($max_parses > 0 && $parse_count > $max_parses) {
        croak("Maximum parse count ($max_parses) exceeded");
    }

    if ($parse_count <= 0) {
	$evaler->[ Parse::Marpa::Internal::Evaluator::PARSE_COUNT ] = 1;
	# Allow semipredication
	my $start_value =
	    $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
	return \(undef) if not defined $start_value;
	return $start_value;
    }

    $evaler->[ Parse::Marpa::Internal::Evaluator::PARSE_COUNT ]++;

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_iteration_changes;
    my $trace_iteration_searches;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_iteration_changes = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ];
        $trace_iteration_searches = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ];
    }

    local ($Data::Dumper::Terse) = 1;

    my $volatile = $grammar->[ Parse::Marpa::Internal::Grammar::VOLATILE ];
    clear_values($evaler) if $volatile;

    # find the "bottom left corner item", by following predecessors,
    # and causes when there is no predecessor

    EVALUATION: for ( ;; ) {
        my $item             = $start_item;
        my $find_left_corner = 1;

        # Look for an item we can (potentially) iterate.
        ITERATION_CANDIDATE: for ( ;; ) {

            # if we set the flag to find the item in the bottom
            # left hand corner, do so
            LEFT_CORNER_CANDIDATE: while ($find_left_corner) {

                # undefine the values as we go along
                $item->[Parse::Marpa::Internal::Earley_item::VALUE] = undef;

                my $predecessor =
                    $item->[Parse::Marpa::Internal::Earley_item::PREDECESSOR];

                # Follow the predecessors all the way until
                # just before the prediction.  The prediction
                # is the item whose "parent" is the same as its
                # Earley set.
                if (defined $predecessor
                    ->[Parse::Marpa::Internal::Earley_item::POINTER] )
                {
                    $item = $predecessor;
                    next LEFT_CORNER_CANDIDATE;
                }

                # At the far left end, see if we have a cause (or
                # child) item.  If so, descend.
                my ( $link_choice, $links ) = @{$item}[
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                ];
                last LEFT_CORNER_CANDIDATE if $link_choice > $#$links;
                $item = $links->[$link_choice]->[1];
                if ($trace_iteration_searches) {
                    print $trace_fh
                        "Seeking left corner at ",
                        Parse::Marpa::brief_earley_item($item), "\n";
                }

            }    # LEFT_CORNER_CANDIDATE

            # We have our candidate, now try to iterate it,
            # exhausting the rule choice if necessary

            # TODO: is this block necessary ?

            my ($token_choice, $tokens,      $link_choice,
                $links,        $rule_choice, $rules,
                )
                = @{$item}[
                Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                Parse::Marpa::Internal::Earley_item::TOKENS,
                Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                Parse::Marpa::Internal::Earley_item::LINKS,
                Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                Parse::Marpa::Internal::Earley_item::RULES,
                ];

            # If we can increment the token_choice, this is our
            # candidate
            if ( $token_choice < $#$tokens ) {
                $token_choice++;
                $item->[Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE] =
                    $token_choice;
                last ITERATION_CANDIDATE;
            }

            # If we can increment the link_choice, this is our
            # candidate
            if ( $link_choice < $#$links ) {
                $link_choice++;
                $item->[Parse::Marpa::Internal::Earley_item::LINK_CHOICE] =
                    $link_choice;
                last ITERATION_CANDIDATE;
            }

            # Iterate rule, if possible
            if ( $rule_choice < $#$rules ) {

                @{$item}[
                    Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    ]
                    = ( ++$rule_choice, 0, 0, );

                if ($trace_iteration_changes) {
                    print $trace_fh
                        "Incremented rule choice for ",
                        Parse::Marpa::brief_earley_item($item), ", ",
                        Parse::Marpa::brief_earley_item($item), " to ",
                        $rule_choice, "\n";
                }

                last ITERATION_CANDIDATE;

            }

            # This candidate could not be iterated.  Set up to look
            # for another.

            @{$item}[
                Parse::Marpa::Internal::Earley_item::VALUE,
                Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                ]
                = ( undef, 0 );

            my ( $successor, $effect ) = @{$item}[
                Parse::Marpa::Internal::Earley_item::SUCCESSOR,
                Parse::Marpa::Internal::Earley_item::EFFECT,
            ];

            $find_left_corner = 0;

            if ( defined $successor ) {
                $item = $successor;
                if ($trace_iteration_changes) {
                    print $trace_fh
                        "Trying to iterate successor ",
                        Parse::Marpa::brief_earley_item($item), "\n";
                }

                # Did the successor have a cause?  If so iterate from
                # it or the "left corner" below it
                my ( $link_choice, $links ) = @{$item}[
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                ];
                if ( $link_choice <= $#$links ) {
                    @{$item}[
                        Parse::Marpa::Internal::Earley_item::VALUE,
                        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                        ]
                        = ( undef, 0 );
                    $item             = $links->[$link_choice]->[1];
                    $find_left_corner = 1;
                }
                next ITERATION_CANDIDATE;

            }

            # If no more candidates, we are finished with all the
            # evaluations for this parse
            return unless defined $effect;

            $item = $effect;
            if ($trace_iteration_searches) {
                print $trace_fh
                    "Trying to iterate effect ",
                    Parse::Marpa::brief_earley_item($item), "\n";
            }

        }    # ITERATION_CANDIDATE

        # We've found and iterated an item.
        # Now try to evaluate it.
        # First, climb the tree, recalculating
        # all the successor and effect values.

        my $reason = "Iterating";

        STEP_UP_TREE: for ( ;; ) {

            RESET_VALUES: {

                my ($token_choice, $tokens,  $link_choice, $links,
                    $rule_choice,  $pointer, $item_set
                    )
                    = @{$item}[
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKENS,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                    Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
                    Parse::Marpa::Internal::Earley_item::POINTER,
                    Parse::Marpa::Internal::Earley_item::SET,
                    ];

                if ( $token_choice <= $#$tokens ) {
                    my ( $predecessor, $value ) =
                        @{ $tokens->[$token_choice] };
                    @{$item}[
                        Parse::Marpa::Internal::Earley_item::VALUE,
                        Parse::Marpa::Internal::Earley_item::PREDECESSOR,
                        ]
                        = ( \$value, $predecessor, );
                    if ($trace_iteration_changes) {
                        my $predecessor_set = $predecessor
                            ->[ Parse::Marpa::Internal::Earley_item::SET, ];
                        print $trace_fh $reason,
                            " token choice for ",
                            Parse::Marpa::brief_earley_item($item), " to ",
                            $token_choice, ", ",
                            $pointer->[Parse::Marpa::Internal::Symbol::NAME],
                            " at ", $predecessor_set, "-", $item_set, " = ",
                            Dumper($value);
                    }
                    weaken( $predecessor
                            ->[Parse::Marpa::Internal::Earley_item::SUCCESSOR]
                            = $item );
                    last RESET_VALUES;
                }

                if ( $link_choice <= $#$links ) {
                    my ( $predecessor, $cause ) = @{ $links->[$link_choice] };
                    weaken(
                        $cause->[Parse::Marpa::Internal::Earley_item::EFFECT]
                            = $item );
                    my $value = initialize_children( $cause, $pointer );
                    @{$item}[
                        Parse::Marpa::Internal::Earley_item::VALUE,
                        Parse::Marpa::Internal::Earley_item::PREDECESSOR,
                        ]
                        = ( \$value, $predecessor, );
                    if ($trace_iteration_changes) {
                        my $predecessor_set = $predecessor
                            ->[ Parse::Marpa::Internal::Earley_item::SET, ];
                        print $trace_fh $reason,
                            " cause choice for ",
                            Parse::Marpa::brief_earley_item($item), " to ",
                            $link_choice, ", ",
                            $pointer->[Parse::Marpa::Internal::Symbol::NAME],
                            " at ", $predecessor_set, "-", $item_set, " = ",
                            Dumper($value);
                    }
                    weaken( $predecessor
                            ->[Parse::Marpa::Internal::Earley_item::SUCCESSOR]
                            = $item );
                    last RESET_VALUES;
                }

            }    # RESET_VALUES

            $reason = "Recalculating Parent";

            my ( $successor, $effect ) = @{$item}[
                Parse::Marpa::Internal::Earley_item::SUCCESSOR,
                Parse::Marpa::Internal::Earley_item::EFFECT,
            ];

            if ( defined $successor ) {
                $item = $successor;
                next STEP_UP_TREE;
            }

            # If no successor or effect, we're at the top of the tree
            last STEP_UP_TREE unless defined $effect;

            $item = $effect;

        }    # STEP_UP_TREE

        # Initialize everything else left unvalued.
        finish_evaluation( $evaler );

        # Rejected evaluations are not yet implemented.
        # Therefore this evaluation pass succeeded.
 
	my $start_value =
	    $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
	# Semipredication allowed
	croak("Parse not evaluated") if not defined $start_value;
	return $start_value;

    }    # EVALUATION

    return;

}

sub Parse::Marpa::Evaluator::show {
    my $evaler = shift;
    my $text  = "";

    croak("No parse supplied") unless defined $evaler;
    my $recognizer = $evaler->[Parse::Marpa::Internal::Evaluator::RECOGNIZER];

    my $start_item = $recognizer->[
        Parse::Marpa::Internal::Recognizer::START_ITEM,
    ];

    local ($Data::Dumper::Terse)       = 1;

    my $value = $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    croak("Parse not evaluated") unless defined $value;

    $text .= show_derivation($start_item);

}

sub show_derivation {
    my $item = shift;
    my $text = "";

    RHS_SYMBOL: for ( ;; ) {

        my $data = 0;

        my ($rules,  $rule_choice,  $links,   $link_choice,
            $tokens, $token_choice, $pointer, $value,
            )
            = @{$item}[
            Parse::Marpa::Internal::Earley_item::RULES,
            Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
            Parse::Marpa::Internal::Earley_item::LINKS,
            Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
            Parse::Marpa::Internal::Earley_item::TOKENS,
            Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
            Parse::Marpa::Internal::Earley_item::POINTER,
            Parse::Marpa::Internal::Earley_item::VALUE,
            ];

        last RHS_SYMBOL unless defined $pointer;
        my $symbol_name = $pointer->[Parse::Marpa::Internal::Symbol::NAME];

        if ( defined $rules and $rule_choice <= $#$rules ) {
            my $rule = $rules->[$rule_choice];
            $text
                .= "[ "
                . Parse::Marpa::brief_earley_item($item) . "] "
                . Parse::Marpa::brief_rule($rule) . "\n";
            $data = 1;
        }

        if ( $token_choice <= $#$tokens ) {
            my ( $predecessor, $token ) = @{ $tokens->[$token_choice] };
            $text
                .= "[ "
                . Parse::Marpa::brief_earley_item($item) . "] "
                . "$symbol_name = "
                . Dumper($token);
            $item = $predecessor;
            next RHS_SYMBOL;
        }

        $text .= Parse::Marpa::brief_earley_item($item) . "No data\n"
            unless $data;

        if ( $link_choice <= $#$links ) {
            my ( $predecessor, $cause ) = @{ $links->[$link_choice] };
            $text .= Parse::Marpa::show_derivation($cause);
            $item = $predecessor;
        }

    }

    $text;

}

1;

=pod

=head1 NAME

Parse::Marpa::Evaluator - A Marpa Evaluator Object

=head1 SYNOPSIS

    my $grammar = new Parse::Marpa::Grammar({ mdl_source => \$mdl });
    my $recce = new Parse::Marpa::Recognizer({ grammar => $grammar });
    my $fail_offset = $recce->text(\("2-0*3+1"));
    croak("Parse failed at offset $fail_offset") if $fail_offset >= 0;

    my $evaler = new Parse::Marpa::Evaluator($recce);

    for (my $i = 0; defined(my $value = $evaler->next()); $i++) {
        croak("Ambiguous parse has extra value: ", $$value, "\n")
	    if $i > $expected;
	say "Ambiguous Equation Value $i: ", $$value;
    }

=head1 DESCRIPTION

Parses are found and evaluated by Marpa's evaluator objects.
Marpa evaluator objects are created with the C<new> constructor,
which requires a Marpa recognizer object.

Marpa allows ambiguous parses, so Marpa's parse evaluator objects are iterators.
Iteration is performed with the C<next> method,
which finds the next parse and returns its value.
If, as is usual, only one parse is wanted, the C<next> method can be called only once.

Each Marpa recognizer should have only one evaluator using it at any one time.
For efficiency,
parses are actually calculated and evaluated in tables kept in the recognizer object.
If one or more evaluators were using the same recognizer at the same time,
they could interfere and produce unpredictable results.

=head2 Volatility

If you accept Marpa's default behavior, you can safely
ignore this section.
By default, Marpa marks all its parses volatile,
and that is always a safe choice.
Non-volatile parses, however, can be optimized by
memoizing node values as they are calculated.
If multiple parses are evaluated in a parse with expensive rule actions,
the boost in efficiency from node value memoization can be major.

Both grammars and parses can be marked volatile.
A parse inherits the volatility marking of the grammar it is created from,
if there was one.

If a user decides to
decides to mark the object non-volatile.
It is up to her to make sure the semantics of an Marpa object
are safe for memoization.
Node values are computed by a function,
and memoization follows the same principles as function memoization.
Nodes may be memoized if they are "pure", that is,
if their return values depend completely on their arguments,
if they have no side effects,
and if their return value is not a reference.
There's an excellent discussion of memoization
in L<Mark Jason Dominus's I<Higher Order Perl>|Parse::Marpa::Doc::Bibliography/Dominus 2005>.

If you're not sure whether your grammar is volatile or not,
just accept Marpa's default behavior.
Also, it is always safe to mark a grammar or a parse volatile yourself.

Marpa will sometimes mark grammars volatile on its own.
Marpa often optimizes the evaluation of sequence productions
by passing a reference to an array among the nodes of the sequence.
This elminates the need to repeatedly copy the array of sequence values
as it is built.
That's a big saving,
especially if the sequence is long,
but the reference to the array is shared data,
and any changes to it are side effects.

Once an object has been marked volatile, whether by Marpa itself
or the user, Marpa throws an exception if there is attempt to mark it non-volatile.
Resetting a grammar to non-volatile will almost always be an oversight,
and one that would be very hard to debug.
The inconvenience of not allowing the user to change his mind seems minor
by comparison.

=head2 Null Values

A "null value" is a symbol's value when it matches the empty string in a parse.
By default, the null value is a Perl undefined, which usually is what makes sense.
If you want something else,
the default null value is a predefined (C<default_null_value>) and can be reset.

A symbol can match the empty string directly, if it is on the left hand side of an empty rule.
It can also match indirectly, through a series of other rules, only some of which need to be empty rules.

Each symbol can have its own null symbol value.
The null symbol value for any symbol is calculated using the action
specified for the empty rule which has that symbol as its left hand side.
The null symbol action is B<not> a rule action.
It's a property of the symbol, and applies whenever the symbol is nulled,
even when the symbol's empty rule is not involved.

For example, in MDL, the following says that whenever C<A> matches the empty
string, it should evaluate to an string.

    A: . q{ 'Oops!  Where did I go!' }.

Null symbol actions are different from rule actions in another important way.
Null symbol actions are run at recognizer creation time and the value of the result
at that point
becomes fixed as the null symbol value.
This is different from rule actions.
During the creation of the recognizer object,
rule actions are B<compiled into closures>.
These rule closures are run during parse evaluation,
whenever a node for that rule needs its value recalculated,
and may produce different values every time they are run.

I treat null symbol actions differently for efficiency.
They have no child values,
and a fixed value is usually what is wanted.
If you want to calculate a symbol's null value with a closure run at parse evaluation time,
the null symbol action can return a reference to a closure.
The parent rules with that nullable symbol on their right hand side
can then be set up so they run the closure returned as the value of null symbol.

As mentioned,
null symbol values are properties of the symbol, not of the rule.
A null value is used whenever the corresponding symbol is a "highest null value"
in a derivation,
whether or not that happened directly through that symbol's empty rule.

=head3 Detailed Example

Suppose a grammar has these rules

    S: A, Z. # Call me the start rule, or Rule 0

    A: . q{!}. # Call me Rule 1

    A: B, C. q{"I'm sometime null and sometimes not"} # Call me Rule 2

    B: . q{'No B'}. # Call me Rule 3

    C: . q{'No C'}. # Call me Rule 4

    C: Z.  # Call me Rule 5

    Z: /Z/. q{'Zorro was here'}. # Call me Rule 6

If the input is the string "C<Z>",
both C<B> and C<C> will match the empty string.
So will the symbol C<A>.
Since C<A> produces both C<B> and C<C> in the derivation,
and since the rule that produces C<A> is not an empty rule,
C<A> is a "highest null symbol",
Therefore, C<A>'s
null value,
the string "C<!>",
which is computed from the action for Rule 1,
is the value of the derivation.

Note carefully several things about this example.
First, Rule 1 is not actually in the derivation of C<A>:

      A -> B C   (Rule 2)
      -> C       (Rule 3)
      ->         (Rule 4)

Second, in the above derivation, C<B> and C<C> also have null values,
which play no role in the result.
Third, Rule 2 has a proper rule action,
and it plays no role in the result either.

=head3 Principles

Marpa's determines null symbol values follows these principles:

=over 4

=item 1

Rules which produce nothing don't count.

=item 2

Rules which produce something do count.

=item 3

A symbol counts when it appears in a rule that counts.

=item 4

A symbol does not count when it appears in a rule that does not count.

=item 5

Regardless of Principles 1 through 4, the start symbol always counts.

=back

In evaluating a derivation, Marpa uses the semantics of rules and symbols which "count",
and ignores those rules and symbols which "don't count."
The value of an empty string, for Marpa, is always the null value of a "highest null symbol".
A "highest null symbol" will always appear in a rule which "counts",
or speaking more carefully, in a non-empty rule.

There's one special case:
when the whole grammar takes the empty string as input,
and recognizes that it has parsed it successfully.
That's called a "null parse".
Whether or not a null parse is possible depends on the grammar.
In a "null parse", the entire grammar "results in nothing".
Null parses are the reason for Principle 5, above.
The value of a null parse is null value of the start symbol.

If you think some of the rules or symbols that Marpa believes "don't count"
are important in your grammar,
Marpa can probably accommodate your ideas.
First, determine what your null semantics mean for every nullable symbol when it is
a "highest null symbol".
Then put those semantics into the each nullable symbol's null actions.
If fixing the null value at parse creation time is not possible in your semantics,
have your null actions return a reference to a closure and run that
closure in a parent node.


=head1 METHODS

=head2 new

    my $evaler = new Parse::Marpa::Evaluator($recce);

    my $evaler = new Parse::Marpa::Evaluator($recce, $location);

Creates an evaluator object and finds the first parse.
On success, returns the evaluator object.
The user may get the value of the first parse with C<Parse::Marpa::Evaluator::value()>. 
She may iterate through the other parses with C<Parse::Marpa::Evaluator::next()>.

If no parse is found, returns undefined.
Other failures are thrown as exceptions.

The I<parse_end> argument is optional.
If provided, it must be the number of the earleme at which
the parse ends.
In the case of a still active parse in offline mode,
the default is to parse to the end of the input.

C<initial()> may be run as often as you like on the same parse,
with or without changing the arguments to C<initial()>.
Each call to C<initial()> resets the iteration of the parse's values to the beginning.

In case of an exhausted parse,
the default is to end the parse
at the point at which the parse was exhausted.
This default isn't very helpful, frankly, and if I
think of anything better I'll change it.
An exhausted parse is a failed parse unless
you're trying advanced wizardry.
Failed parses are usually addressed by fixing the grammar or the
input.

The alternative to offline mode is online mode, which is bleeding-edge.
In online mode there is no obvious "end of input".
Online mode is not well tested, and
Marpa doesn't yet provide a lot of tools for working with it.
It's up to the user to determine where to look for parses,
perhaps using her specific knowledge of the grammar and the problem
space.
The C<Parse::Marpa::Recognizer::find_complete_rule()> method,
documented in L<the diagnostics document|Parse::Marpa::DIAGNOSTIC>,
is a prototype of the methods that will be needed in online mode.

=head2 next

    my $value = $evaler->next();

Takes a parse object as its only argument,
and performs the next iteration through its values.
The iteration must have been initialized with
C<Parse::Marpa::Evaluator::initial()>.
Returns 1 if there was a next iteration.
Returns undefined when there are no more iterations.
Other failures are exceptions.

Parses are iterated from rightmost to leftmost, but their order
may be manipulated by assigning priorities to the rules and
terminals.

=head2 value

Given an evaluator object whose value has been calculated with
C<next>,
returns a reference to its current value.
It returns undefined in the case of a Marpa "no value".
Failures are thrown as exceptions.

Since the C<next> method returns a reference to the value of the parse,
this method is rarely needed.
Its main use is for the unusual case where both a Perl
undefined and a Marpa "no value" may be the value of a parse,
and it is necessary to distinguish between them.
In both these circumstances, the return value of the
C<next> method would be a reference to an undefined.

A Marpa "no value" is the result of asking for the value of the
parse at a node where no value was ever calculated.
A Marpa "no value" is B<not> ever a default value,
the result of a nulling rule,
and or the result of a non-existent optional item.
All of these have as their value a Perl 5 undefined.
These undefineds count as "node values"
and the C<value> method returns them as a reference to an undefined.

Marpa "no values" will not occur as long as you use the defaults:
offline mode and the default end parse location.
If you don't stick to the defaults,
then, in some cases,
which will usually be the result of advanced wizardry gone wrong,
Marpa will not find a node value.
This is considered a Marpa "no node value".

=head1 IMPLEMENTATION

Marpa, if a grammar optimizes sequences by returning references,
marks the grammar volatile.
Marpa gives optimization of sequences priority
over memoization of node values because
node value memoization has no payoff unless multiple parses are evaluated
from a single parse object, which is not the usual case.
Optimization of sequence evaluation almost always pays off handsomely.

A possible future extension is to add the ability to 
label only particular rules volatile.
But there's something to be said for keeping interfaces simple.
If a grammar writer is really looking for speed,
she can let the grammar default to volatile,
then use side effects and her own, targeted caching and memoizations.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
