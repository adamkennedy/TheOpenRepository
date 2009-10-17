package Marpa::MDL::Internal::Old_Actions;

use 5.010;
use strict;
use warnings;

## no critic (Subroutines::RequireArgUnpacking
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
## no critic (Variables::ProhibitPackageVars)

our $regex_data = [];

sub first_arg {
    return $_[0];
}

sub concatenate_lines {
    return ( scalar @_ ) ? ( join "\n", ( grep {$_} @_ ) ) : undef;
}

sub grammar { return $_[0] }

# production paragraph:
# non structural production sentences,
# production sentence,
# non structural production sentences,
# optional action sentence,
# non structural production sentences.
sub production_paragraph {
    my $action = $_[3];
    my $other_key_value = join ",\n", map { $_ // q{} } @_[ 0, 2, 4 ];
    my $result =
          'push @{$new_rules}, ' . "{\n"
        . $_[1] . ",\n"
        . ( defined $action ? ( $action . ",\n" ) : q{} )
        . $other_key_value . "\n};";
    our @implicit_terminals;
    if (@implicit_terminals) {
        $result .= "\n" . 'push @{$new_terminals},' . "\n";
        while ( my $implicit_terminal = shift @implicit_terminals ) {
            $result .= '    [' . $implicit_terminal . "],\n";
        }
        $result .= ";\n";
    } ## end if (@implicit_terminals)
    our @implicit_rules;
    if (@implicit_rules) {
        $result .= "\n" . 'push @{$new_rules},' . "\n";
        while ( my $implicit_production = shift @implicit_rules ) {
            $result .= '    {' . $implicit_production . "},\n";
        }
        $result .= " ;\n";
    } ## end if (@implicit_rules)
    return $result;
} ## end sub production_paragraph

# non structural production sentence: /priority/, integer, period.
sub non_structural_production_sentence { return q{ priority => } . $_[1] }

# action sentence:
# optional /the/, /action/, /is/, action specifier, period.
sub long_action_sentence {
    return '    action =>' . $_[3];
}

# action sentence: action specifier, period.
sub short_action_sentence {
    return '    action =>' . $_[0];
}

# definition: predefined setting, period.  q{ $_[0] }.  priority 1000.
sub definition_of_predefined { return $_[0] }

# semantics setting:  optional /the/, /semantics/, copula, /perl5/.
sub semantics_predicate {
    return q{$new_semantics = '} . $_[3] . qq{';\n};
}

# semantics setting: /perl5/, copula, optional /the/, /semantics/.
sub semantics_subject {
    return q{$new_semantics = '} . $_[0] . qq{';\n};
}

# version setting: optional /the/, /version/, copula, version number.
sub version_predicate {
    return q{$new_version = '} . $_[3] . qq{';\n};
}

# version setting: /version number/, copula, optional /the/, /version/.
sub version_subject {
    return q{$new_version = '} . $_[0] . qq{';\n};
}

# start symbol setting: optional /the/, /start/, /symbol/, copula,
# symbol phrase.
sub start_symbol_predicate {
    return q{$new_start_symbol = '} . $_[4] . qq{';\n};
}

# start symbol setting: symbol phrase, copula, optional /the/, /start/,
# /symbol/, .
sub start_symbol_subject {
    return q{$new_start_symbol = } . $_[0] . qq{;\n};
}

# default lex prefix setting: regex, copula, optional /the/, /default/,
# /lex/, /prefix/, .
sub default_lex_prefix_subject {
    return q{$new_default_lex_prefix = } . $_[0] . qq{;\n};
}

# default lex prefix setting: optional /the/, /default/, /lex/,
# /prefix/, copula, regex, .
sub default_lex_prefix_predicate {
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return q{$new_default_lex_prefix = } . $_[5] . qq{;\n};
}

# default null value setting: string specifier, copula, optional /the/, /default/,
# /null/, /value/, .
sub default_null_value_subject {
    return q{$new_default_null_value = } . $_[0] . qq{;\n};
}

# default null value setting: optional /the/, /default/, /null/,
# /value/, copula, string specifier, .
sub default_null_value_predicate {
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return q{$new_default_null_value = } . $_[5] . qq{;\n};
}

# string definition:
# symbol phrase, /is/, string specifier, period.
sub string_definition {
    return '$strings{' . q{'} . $_[0] . q{'} . '}' . q{ = } . $_[2] . qq{;\n};
}

# default action setting:
# action specifier, /is/, optional /the/, /default/, /action/.
sub default_action_subject {
    return q{ $new_default_action = } . $_[0] . qq{;\n};
}

# default action setting:
# optional /the/, /default/, /action/, /is/, action specifier.
sub default_action_predicate {
    return q{ $new_default_action = } . $_[4] . qq{;\n};
}

# literal string: q string.  q{ $_[0] }.
sub q_string { return $_[0] }

# production sentence: lhs, production copula, rhs, period.
sub production_sentence {
    return $_[0] . "\n," . $_[2];
}

# symbol phrase: symbol word sequence.
sub symbol_phrase {
    return Marpa::MDL::canonical_symbol_name( join q{-}, @_ );
}

# lhs: symbol phrase.
sub lhs { return '    lhs => ' . q{'} . $_[0] . q{'} }

# rhs: .
sub empty_rhs { return '    rhs => []' }

# rhs: comma separated rhs element sequence.
sub comma_separated_rhs { return '    rhs => [' . join( q{, }, @_ ) . ']' }

# rhs: symbol phrase, /sequence/.
sub sequence_rhs {
    return q{rhs => ['} . $_[0] . qq{'],\n} . qq{min => 1,\n};
}

# rhs: /optional/, symbol phrase, /sequence/.
sub optional_sequence_rhs {
    return q{rhs => ['} . $_[1] . qq{'],\n} . qq{min => 0,\n};
}

# rhs: symbol phrase, /separated/, symbol phrase, /sequence/.
sub separated_sequence_rhs {
    return
          q{rhs => ['}
        . $_[2]
        . qq{'],\n}
        . q{separator => '}
        . $_[0]
        . qq{',\n}
        . qq{min => 1,\n};
} ## end sub separated_sequence_rhs

# rhs: /optional/, symbol phrase, /separated/, symbol phrase, /sequence/.
sub optional_separated_sequence_rhs {
    return
          q{rhs => ['}
        . $_[3]
        . qq{'],\n}
        . q{separator => '}
        . $_[1]
        . qq{',\n}
        . qq{min => 0,\n};
} ## end sub optional_separated_sequence_rhs

# mandatory rhs element: rhs symbol specifier.
sub mandatory_rhs_element { return q{'} . $_[0] . q{'} }

# optional rhs element: /optional/, rhs symbol specifier.
sub optional_rhs_element {
    my $symbol_phrase          = $_[1];
    my $optional_symbol_phrase = $symbol_phrase . ':optional';
    our %implicit_rules;
    if ( not defined $implicit_rules{$optional_symbol_phrase} ) {
        $implicit_rules{$optional_symbol_phrase} = 1;
        our @implicit_rules;
        push
            @implicit_rules,
            q{ lhs => '}
            . $optional_symbol_phrase . q{', }
            . q{ rhs => [ '}
            . $symbol_phrase
            . q{' ], }
            . q{ action => '}
            . __PACKAGE__
            . q{::first_arg'};
        push
            @implicit_rules,
            q{ lhs => '} . $optional_symbol_phrase . q{', } . q{ rhs => [], };
    } ## end if ( not defined $implicit_rules{$optional_symbol_phrase...})
    return q{'} . $optional_symbol_phrase . q{'};
} ## end sub optional_rhs_element

# rhs_symbol specifier: symbol phrase.
sub rhs_symbol_phrase_specifier { return $_[0] }

# rhs symbol specifier: regex.
sub rhs_regex_specifier {
    my $regex = $_[0];
    my ( $symbol, $new ) =
        Marpa::MDL::gen_symbol_from_regex( $regex, $regex_data );
    if ($new) {
        our @implicit_terminals;
        push @implicit_terminals,
            q{'} . $symbol . q{' => } . '{' . q{ regex => } . $regex . ' }';
    }
    return $symbol;
} ## end sub rhs_regex_specifier

# terminal sentence:
# symbol phrase, /matches/, regex, period.
sub regex_terminal_sentence {
    return
          q{push @{$new_terminals}, [ '}
        . $_[0]
        . q{' => }
        . '{ regex => '
        . $_[2] . '}'
        . qq{ ] ;\n};
} ## end sub regex_terminal_sentence

# terminal sentence:
# /match/, symbol phrase, /using/, string specifier, period.
sub string_terminal_sentence {
    return
          q{push @{$new_terminals}, [ '}
        . $_[1]
        . q{' => }
        . '{ action =>'
        . $_[3] . '}'
        . qq{ ];\n};
} ## end sub string_terminal_sentence

# string specifier: symbol phrase.
sub string_name_specifier {
    return '$strings{ ' . q{'} . $_[0] . q{'} . ' }';
}
## use critic

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
