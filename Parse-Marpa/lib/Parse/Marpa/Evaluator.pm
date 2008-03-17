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

    my $opaque = $grammar->[ Parse::Marpa::Internal::Grammar::OPAQUE ];
    clear_values($evaler) if $opaque;

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
            $text .= show_derivation($cause);
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
Evaluators are created with the C<new> constructor,
which requires a Marpa recognizer object.

Marpa allows ambiguous parses, so evaluator objects are iterators.
Iteration is performed with the C<next> method,
which finds the next parse and returns its value.
Often only one parse is needed, in which case the C<next> method is called only once.

The evaluator does its work in tables kept
in the recognizer object.
Each Marpa recognizer should have only one evaluator using it at any one time.
If multiple evaluators
use the same recognizer at the same time,
they may produce incorrect results.

=head2 Node Memoization

If you accept Marpa's default behavior,
there will be no node memoization and
you can safely
ignore the question of opacity.
But when multiple parses are evaluated in a parse with expensive rule actions,
the boost in efficiency from node value memoization can be major.

If the defaults are used, Marpa will mark all its evaluators opaque.
That is always a safe choice.

Grammars and recognizers can be marked opaque.
A recognizer created from an opaque grammar is marked opaque.
A recognizer created from a grammar marked transparent is marked transparent,
unless an C<opaque> named argument supplied at recognizer creation time
overrides that marking.
A recognizer created from a grammar without a opacity marking is marked opaque,
unless a C<opaque> named argument supplied at recognizer creation time
overrides that marking.
Once a recognizer object has been created,
its opacity setting cannot be changed.

If a user decides to mark an object transparent,
it is up to her to make sure all the
evaluators created from that object are safe for node memoization.
An evaluator is safe for node memoization only if all of its nodes are
safe for memoization.
Node values are computed by Perl 5 code,
and node memoization follows the same principles as function memoization.
For a node to be safe for memoization, it must be transparent.
A node is transparent only
if it is always safe to substitute a constant value for the node's action.

Here are some hints for making actions transparent:
The code must have no side effects.
The return value should not be a reference.
The return value must depend completely on the return values of the child nodes.
All child nodes must be transparent as well.
Any subroutines or functions must be transparent.

Exceptions to these rules can be made, but you have to know what you're doing.
There's an excellent discussion of memoization
in L<Mark Jason Dominus's I<Higher Order Perl>|Parse::Marpa::Doc::Bibliography/Dominus 2005>.
If you're not sure whether your semantics are opaque or not,
just accept Marpa's default behavior.
Also, it is always safe to mark a grammar or a recognizer opaque.

Marpa will sometimes mark grammars opaque on its own.
Marpa often optimizes the evaluation of sequence productions
by passing a reference to an array between the nodes of the sequence.
This elminates the need to repeatedly copy the array of sequence values
as it is built.
That's a big saving,
especially if the sequence is long,
but the reference to the array is shared data,
and the changes to the array are side effects.

Once an object has been marked opaque, whether by Marpa itself
or the user, Marpa throws an exception if there is an attempt to mark it transparent.
Resetting a grammar to transparent will almost always be an oversight,
and one that would be very hard to debug.

=head2 Null Values

A "null value" is the value used for a symbol's value when it is nulled in a parse.
By default, the null value is a Perl undefined.
If you want something else,
the default null value is a predefined (C<default_null_value>) and can be reset.

Each symbol can have its own null symbol value.
The null symbol value for any symbol is calculated using the action
specified for the empty rule which has that symbol as its left hand side.
The null symbol action is B<not> a rule action.
It's a property of the symbol, and applies whenever the symbol is nulled,
even when the symbol's empty rule is not involved.

For example, in MDL,
the following says that whenever the symbol C<A> matches the empty string,
it should evaluate to a string which expresses surprise.

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
can then be set up so they run that closure.

As mentioned,
null symbol values are properties of a symbol, not of a rule.
A null value is used whenever the corresponding symbol is a "highest null value"
in a derivation,
whether or not that happens directly through that symbol's empty rule.

=head3 Principles

Marpa's determines null symbol values following these principles:

=over 4

=item 1

Nodes which derive the empty string don't count.

=item 2

All the other nodes do count.

=item 3

The start symbol counts.

=item 4

If a node counts, all the symbols on both the lhs and rhs of the corresponding rule count.

=item 5

Other symbols don't count.

=back

In evaluating a derivation, Marpa uses the semantics of nodes and symbols which count,
and ignores those rules and symbols which don't count.
The value of an empty string, for Marpa, is always the null value of a "highest null symbol".
Except in the special case of a null parse,
the "highest null symbol" will always appear in a rule which counts,
in other words, in a non-empty rule.

A null parse, the case where the start symbol produces the empty string, is special.
Whether or not a null parse is possible depends on the grammar.
Null parses are the reason for Principle 3.
The value of a null parse is null value of the start symbol.

If you think some of the rules or symbols that Marpa believes don't count
are important in your grammar,
Marpa can probably accommodate your ideas.
First,
for every nullable symbol,
determine how to calculate the value which your null semantics produces
when that nullable symbol is a "highest null symbol".
If it's a constant, write a null action for that symbol which returns that constant.
If your null semantics do not produce a constant value by recognizer creation time,
write a null action which returns a reference to a closure
and arrange to have that closure run by the parent node.

=head3 Detailed Example

Suppose a grammar has these rules

    S: A, Z. q{ $_->[0] . ", but " . $_->[1] }. # Call me the start rule
    note: you can also call me Rule 0.

    A: . q{'A is missing'}. # Call me Rule 1

    A: B, C. q{"I'm sometimes null and sometimes not"}. # Call me Rule 2

    B: . q{'B is missing'}. # Call me Rule 3

    C: . q{'C is missing'}. # Call me Rule 4

    C: Z.  q{'C matches Z'}. # Call me Rule 5

    Z: /Z/. q{'Zorro was here'}. # Call me Rule 6

If the input is the string "C<Z>",
the grammar derives it as follows:

    S -> A Z        (Rule 0)
      -> A "Z"      (Z produces "Z", by Rule 6)
      -> B C "Z"    (A produces B C, by Rule 2)
      -> B "Z"      (C produces the empty string, by Rule 4)
      -> "Z"        (B produces the empty string, by Rule 3)

The parse tree can be described as follows:

    Node 0 (root): S (2 children, nodes 1 and 4)
        Node 1: A (2 children, nodes 2 and 3)
	    Node 2: B (matches empty string)
	    Node 3: C (matches empty string)
	Node 4: Z (matches "Z")

Here's the sentence each node derives and what it evaluates to

                      Symbol      Sentence     Value
                                  Derived

    Node 0:              S           Z         "A is missing, but Zorro is here"
        Node 1:          A         Empty       "A is missing"
	    Node 2:      B         Empty       No value
	    Node 3:      C         Empty       No value
	Node 4:          Z           Z         "Zorro was here"

In this derivation, symbols C<B> and C<C> are nulled.
Nodes 2 and 3 therefore do not count.
Symbol C<A> is also nulled, so Node 1 also does not count.

Two symbols are not nulled.
The symbol C<S> derives the string "C<Z>".
Symbol C<Z> also derives the string "C<Z>".
Therefore, nodes 0 and 4 count.

Where nodes count, symbols in the corresponding rules count.
Rule 6 is a terminal rule, and its only symbol is C<Z>.
Rules 0 has the symbol C<S> on its lhs, and
C<A> and C<Z> on its rhs, so all these count.

Another way of looking at this is that C<A> is the "highest null symbol"
in a null derivation,
so that it is the only nulled symbol to count in that derivation.
C<S> is the start symbol, which always counts.
Symbol C<Z> is not nulled.
Symbols which are not nulled always wind up counting
because no node can be nulled unless its symbol is.
Therefore, symbol C<Z> counts.

Since the symbol C<Z> is not nulled,
it is evaluated normally, using Rule 6.
This makes its value, "C<Zorro was here>".
Since the symbols C<B> and C<C> are nulled and do not count,
nothing about them plays any role in calculating the value of the parse.

The symbol C<A> is nulled, but it counts by virtue of its appearance in
a node which is not nulled,
making it the "highest null symbol".
C<A> returns its null symbol value.
C<A>'s null symbol value is calculated by running the action
for the empty rule which has C<A> as its lhs, which is Rule 1.
C<A>'s value is "C<A is missing>".

It is important to note that Rule 1 is not actually used in the derivation.
Rule 1 is used because it
defines the null symbol value for C<A>.

The other rule which counts is Rule 0, the start rule.
Its value is calculated using its action and the values for the symbols
on its rhs.
That value is "C<A is missing, but Zorro was here>",
This becomes the value of C<S>, Rule 0's lhs.
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
Where parsing ends if no second argument is provided depends on the state
of the recognizer.
The usual circumstances are that
parsing is in offline mode
and the parse in the recognizer is still active or, in other words,
the parse has not been exhausted.
In this case parsing ends at the end of the input,
or in other words,
at the last earleme at which a token ends.

If the parse was exhausted in the recognizer,
the default is for parsing to end with the earleme
at which the parse was exhausted.
Usually that won't be very helpful,
since an exhausted parse is typically a failed parse.
Failed parses are usually addressed by fixing the grammar or the
input.

The alternative to offline mode is online or streaming mode,
which is bleeding-edge.
In online mode there is no obvious "end of input".
Marpa doesn't yet provide a lot of tools for working with online mode.
It's up to the user to determine where to look for parses,
perhaps using her specific knowledge of the grammar and the problem
space.
The C<Parse::Marpa::Recognizer::find_complete_rule()> method,
documented in L<the diagnostics document|Parse::Marpa::DIAGNOSTIC>,
is a prototype of the methods that will be needed for online mode.

=head2 next

    my $value = $evaler->next();

Iterates the evaluator object, returning a reference to the value of the next parse.
If there are no more parses, returns undefined.
Successful parses may evaluate to a Perl 5 undefined,
which the C<next> method will return as a reference to an undefined.
Failures are thrown as exceptions.

Parses are iterated from rightmost to leftmost.
The parse order may be manipulated by assigning priorities to the rules and
terminals.

A failed parse does not always show up as an exhausted parse in the recognizer.
Just because the recognizer was actively parsing when it was used to create
the evaluator, does not mean that the input matches the grammar.
If it does not match, there will be no parses and the C<next> method will
return undefined the first time it is called.

=head1 IMPLEMENTATION

Marpa, if a grammar optimizes sequences by returning references,
marks the grammar opaque.
Marpa gives optimization of sequences priority
over memoization of node values because
node value memoization has no payoff unless multiple parses are evaluated,
which is not the usual case.
Optimization of sequence evaluation almost always pays off quickly and handsomely.

A possible future extension is to enable the user to 
label only particular rules opaque, and to allow node memoization
on a rule by rule basis.
But there's something to be said for keeping things simple.
If a grammar writer is really looking for speed,
she can let the grammar default to opaque,
then use side effects and targeted caching and memoization.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
