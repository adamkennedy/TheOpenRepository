package Marpa::MDL::Internal::New_Actions;

use 5.010;
use strict;
use warnings;

## no critic (Subroutines::RequireArgUnpacking
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
## no critic (Variables::ProhibitPackageVars)

sub new {
    my $class = shift;
    my $self  = {
        regex_data         => [],
        implicit_terminals => [],
        implicit_rule_hash => {},
        implicit_rules     => [],
    };
    return bless $self, $class;
} ## end sub new

sub first_arg {
    return $_[1];
}

sub concatenate_lines {
    shift;
    return ( scalar @_ ) ? ( join "\n", ( grep {$_} @_ ) ) : undef;
}

sub grammar {
    my ($self, $text) = @_;
    my $result = $text;
    my $implicit_terminals = $self->{implicit_terminals};
    if ($implicit_terminals) {
        $result .= "\n" . 'push @{$new_terminals},' . "\n";
        while ( my $implicit_terminal = shift @{$implicit_terminals} ) {
            $result .= '    [' . $implicit_terminal . "],\n";
        }
        $result .= ";\n";
    }
    my $implicit_rules = $self->{implicit_rules};
    if ($implicit_rules) {
        $result .= "\n" . 'push @{$new_rules},' . "\n";
        while ( my $implicit_production = shift @{$implicit_rules} ) {
            $result .= '    {' . $implicit_production . "},\n";
        }
        $result .= " ;\n";
    }
    return $result;
}

# production paragraph:
# non structural production sentences,
# production sentence,
# non structural production sentences,
# optional action sentence,
# non structural production sentences.
sub production_paragraph {
    shift;
    my $action = $_[3];
    my $other_key_value = join ",\n", map { $_ // q{} } @_[ 0, 2, 4 ];
    my $result =
          'push @{$new_rules}, ' . "{\n"
        . $_[1] . ",\n"
        . ( defined $action ? ( $action . ",\n" ) : q{} )
        . $other_key_value . "\n};";
    return $result;
} ## end sub production_paragraph

# non structural production sentence: /priority/, integer, period.
sub non_structural_production_sentence { return q{ priority => } . $_[2] }

# action sentence:
# optional /the/, /action/, /is/, action specifier, period.
sub long_action_sentence {
    return '    action =>' . $_[4];
}

# action sentence: action specifier, period.
sub short_action_sentence {
    return '    action =>' . $_[1];
}

# definition: predefined setting, period.  q{ $_[0] }.  priority 1000.
sub definition_of_predefined { return $_[1] }

# semantics setting:  optional /the/, /semantics/, copula, /perl5/.
sub semantics_predicate {
    return q{$new_semantics = '} . $_[4] . qq{';\n};
}

# semantics setting: /perl5/, copula, optional /the/, /semantics/.
sub semantics_subject {
    return q{$new_semantics = '} . $_[1] . qq{';\n};
}

# version setting: optional /the/, /version/, copula, version number.
sub version_predicate {
    return q{$new_version = '} . $_[4] . qq{';\n};
}

# version setting: /version number/, copula, optional /the/, /version/.
sub version_subject {
    return q{$new_version = '} . $_[1] . qq{';\n};
}

# start symbol setting: optional /the/, /start/, /symbol/, copula,
# symbol phrase.
sub start_symbol_predicate {
    return q{$new_start_symbol = '} . $_[5] . qq{';\n};
}

# start symbol setting: symbol phrase, copula, optional /the/, /start/,
# /symbol/, .
sub start_symbol_subject {
    return q{$new_start_symbol = } . $_[1] . qq{;\n};
}

# default lex prefix setting: regex, copula, optional /the/, /default/,
# /lex/, /prefix/, .
sub default_lex_prefix_subject {
    return q{$new_default_lex_prefix = } . $_[1] . qq{;\n};
}

# default lex prefix setting: optional /the/, /default/, /lex/,
# /prefix/, copula, regex, .
sub default_lex_prefix_predicate {
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return q{$new_default_lex_prefix = } . $_[6] . qq{;\n};
}

# default null value setting: string specifier, copula, optional /the/, /default/,
# /null/, /value/, .
sub default_null_value_subject {
    return q{$new_default_null_value = } . $_[1] . qq{;\n};
}

# default null value setting: optional /the/, /default/, /null/,
# /value/, copula, string specifier, .
sub default_null_value_predicate {
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return q{$new_default_null_value = } . $_[6] . qq{;\n};
}

# string definition:
# symbol phrase, /is/, string specifier, period.
sub string_definition {
    return '$strings{' . q{'} . $_[1] . q{'} . '}' . q{ = } . $_[3] . qq{;\n};
}

# default action setting:
# action specifier, /is/, optional /the/, /default/, /action/.
sub default_action_subject {
    return q{ $new_default_action = } . $_[1] . qq{;\n};
}

# default action setting:
# optional /the/, /default/, /action/, /is/, action specifier.
sub default_action_predicate {
    return q{ $new_default_action = } . $_[5] . qq{;\n};
}

# literal string: q string.  q{ $_[1] }.
sub q_string { return $_[1] }

# production sentence: lhs, production copula, rhs, period.
sub production_sentence {
    return $_[1] . "\n," . $_[3];
}

# symbol phrase: symbol word sequence.
sub symbol_phrase {
    shift;
    return Marpa::MDL::canonical_symbol_name( join q{-}, @_ );
}

# lhs: symbol phrase.
sub lhs { return '    lhs => ' . q{'} . $_[1] . q{'} }

# rhs: .
sub empty_rhs { return '    rhs => []' }

# rhs: comma separated rhs element sequence.
sub comma_separated_rhs { shift; return '    rhs => [' . join( q{, }, @_ ) . ']' }

# rhs: symbol phrase, /sequence/.
sub sequence_rhs {
    return q{rhs => ['} . $_[1] . qq{'],\n} . qq{min => 1,\n};
}

# rhs: /optional/, symbol phrase, /sequence/.
sub optional_sequence_rhs {
    return q{rhs => ['} . $_[2] . qq{'],\n} . qq{min => 0,\n};
}

# rhs: symbol phrase, /separated/, symbol phrase, /sequence/.
sub separated_sequence_rhs {
    return
          q{rhs => ['}
        . $_[3]
        . qq{'],\n}
        . q{separator => '}
        . $_[1]
        . qq{',\n}
        . qq{min => 1,\n};
} ## end sub separated_sequence_rhs

# rhs: /optional/, symbol phrase, /separated/, symbol phrase, /sequence/.
sub optional_separated_sequence_rhs {
    return
          q{rhs => ['}
        . $_[4]
        . qq{'],\n}
        . q{separator => '}
        . $_[2]
        . qq{',\n}
        . qq{min => 0,\n};
} ## end sub optional_separated_sequence_rhs

# mandatory rhs element: rhs symbol specifier.
sub mandatory_rhs_element { return q{'} . $_[1] . q{'} }

# optional rhs element: /optional/, rhs symbol specifier.
sub optional_rhs_element {
    my ($self, $dummy, $symbol_phrase) = @_;
    my $optional_symbol_phrase = $symbol_phrase . ':optional';
    my $implicit_rule_hash = $self->{implicit_rule_hash};
    my $implicit_rules = $self->{implicit_rules};
    if ( not defined $implicit_rule_hash->{$optional_symbol_phrase} ) {
        $implicit_rule_hash->{$optional_symbol_phrase} = 1;
        push
            @{$implicit_rules},
            q{ lhs => '}
            . $optional_symbol_phrase . q{', }
            . q{ rhs => [ '}
            . $symbol_phrase
            . q{' ], }
            . q{ action => '}
            . __PACKAGE__
            . q{::first_arg'};
        push
            @{$implicit_rules},
            q{ lhs => '} . $optional_symbol_phrase . q{', } . q{ rhs => [], };
    } ## end if ( not defined $implicit_rules{$optional_symbol_phrase...})
    return q{'} . $optional_symbol_phrase . q{'};
} ## end sub optional_rhs_element

# rhs_symbol specifier: symbol phrase.
sub rhs_symbol_phrase_specifier { return $_[1] }

# rhs symbol specifier: regex.
sub rhs_regex_specifier {
    my ( $self, $regex ) = @_;
    my ( $symbol, $new ) =
        Marpa::MDL::gen_symbol_from_regex( $regex, $self->{regex_data} );
    if ($new) {
        push @{ $self->{implicit_terminals} },
            qq[ '$symbol'  => { regex => $regex } ];
    }
    return $symbol;
} ## end sub rhs_regex_specifier

# terminal sentence:
# symbol phrase, /matches/, regex, period.
sub regex_terminal_sentence {
    return
          q{push @{$new_terminals}, [ '}
        . $_[1]
        . q{' => }
        . '{ regex => '
        . $_[3] . '}'
        . qq{ ] ;\n};
} ## end sub regex_terminal_sentence

# terminal sentence:
# /match/, symbol phrase, /using/, string specifier, period.
sub string_terminal_sentence {
    return
          q{push @{$new_terminals}, [ '}
        . $_[2]
        . q{' => }
        . '{ action =>'
        . $_[4] . '}'
        . qq{ ];\n};
} ## end sub string_terminal_sentence

# string specifier: symbol phrase.
sub string_name_specifier {
    return '$strings{ ' . q{'} . $_[1] . q{'} . ' }';
}
## use critic

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
