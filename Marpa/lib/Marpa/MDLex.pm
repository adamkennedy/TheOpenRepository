package Marpa::MDLex;

use 5.010;
use warnings;
use strict;

# It's all integers, except for the version number
use integer;

#<<< no perltidy
use Marpa::Offset qw(

    :package=Marpa::Internal::Symbol

    ID NAME
    PRIORITY
    PREFIX SUFFIX
    REGEX

);

#>>> End of no perltidy

# REGEX           - regex
# PRIORITY        - order, for lexing
# ACTION          - lexing action specified by user
# PREFIX          - lexing prefix specified by user

use Marpa::Offset qw(

    :package=Marpa::Internal::MDLex

    RECCE { The Marpa recognizer used }

    LEXERS { An array (indexed by symbol id)
    of the lexer for each symbol }

    CURRENT_LEXABLES

    SYMBOLS { array of symbol refs }

    DEFAULT_LEX_PREFIX { default prefix for lexing }
    DEFAULT_LEX_SUFFIX { default suffix for lexing }

    AMBIGUOUS_LEX { lex ambiguously? }

    TRACE_FILE_HANDLE
    TRACING { Master flag.  Set if any tracing is being done.
    Limits overhead for non-tracing processes. }

    TRACE_LEX_MATCHES
    TRACE_LEX_TRIES

    INITIALIZED { All the phase tracking we need.
    At least for now }

);

package Marpa::Internal::MDLex;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use Data::Dumper;
use English qw( -no_match_vars );
use List::Util;
use Carp;

sub Marpa::MDLex::new {
    my ( $class, $args ) = @_;
    $args //= {};

    my $lexer = [];
    bless $lexer, $class;

    # set the defaults and the default defaults
    $lexer->[Marpa::Internal::MDLex::TRACE_FILE_HANDLE] = *STDERR;

    $lexer->[Marpa::Internal::MDLex::DEFAULT_LEX_PREFIX] = q{};
    $lexer->[Marpa::Internal::MDLex::DEFAULT_LEX_SUFFIX] = q{};
    $lexer->[Marpa::Internal::MDLex::AMBIGUOUS_LEX]      = 1;
    $lexer->[Marpa::Internal::MDLex::TRACING]            = 0;
    $lexer->[Marpa::Internal::MDLex::SYMBOLS]            = [];

    $lexer->set($args);
    $lexer->[Marpa::Internal::MDLex::INITIALIZED] = 1;
    return $lexer;

} ## end sub Marpa::MDLex::new

sub Marpa::MDLex::set {
    my ( $lexer, $args ) = @_;
    $args //= {};

    my $initialized = $lexer->[Marpa::Internal::MDLex::INITIALIZED];
    my $tracing = $lexer->[Marpa::Internal::MDLex::TRACING];

    # set trace_fh even if no tracing, because we may turn it on in this method
    my $trace_fh = $lexer->[Marpa::Internal::MDLex::TRACE_FILE_HANDLE];

    # Second pass options
    while ( my ( $option, $value ) = each %{$args} ) {
        given ($option) {
            when ('default_lex_prefix') {
                Marpa::exception(
                    "$option option not allowed after lexer is initialized")
                    if $initialized;
                $lexer->[Marpa::Internal::MDLex::DEFAULT_LEX_PREFIX] = $value;
            } ## end when ('default_lex_prefix')
            when ('default_lex_suffix') {
                Marpa::exception(
                    "$option option not allowed after lexer is initialized")
                    if $initialized;
                $lexer->[Marpa::Internal::MDLex::DEFAULT_LEX_SUFFIX] = $value;
            } ## end when ('default_lex_suffix')
            when ('ambiguous_lex') {
                Marpa::exception(
                    "$option option not allowed after lexer is initialized")
                    if $initialized;
                $lexer->[Marpa::Internal::MDLex::AMBIGUOUS_LEX] = $value;
            } ## end when ('ambiguous_lex')
            when ('trace_file_handle') {
                $lexer->[Marpa::Internal::MDLex::TRACE_FILE_HANDLE] = $value;
            }
            when ('trace_lex') {
                $lexer->[Marpa::Internal::MDLex::TRACE_LEX_TRIES] =
                    $lexer->[Marpa::Internal::MDLex::TRACE_LEX_MATCHES] =
                    $value;
                if ($value) {
                    say {$trace_fh} "Setting $option option";
                    $lexer->[Marpa::Internal::MDLex::TRACING] = 1;
                }
            } ## end when ('trace_lex')
            when ('trace_lex_tries') {
                $lexer->[Marpa::Internal::MDLex::TRACE_LEX_TRIES] = $value;
                if ($value) {
                    say {$trace_fh} "Setting $option option";
                    $lexer->[Marpa::Internal::MDLex::TRACING] = 1;
                }
            } ## end when ('trace_lex_tries')
            when ('trace_lex_matches') {
                $lexer->[Marpa::Internal::MDLex::TRACE_LEX_MATCHES] = $value;
                if ($value) {
                    say {$trace_fh} "Setting $option option";
                    $lexer->[Marpa::Internal::MDLex::TRACING] = 1;
                }
            } ## end when ('trace_lex_matches')
            default {
                Marpa::exception("$_ is not an available MDLex option");
            }
        } ## end given
    } ## end while ( my ( $option, $value ) = each %{$args} )

    return 1;
} ## end sub Marpa::MDLex::set

sub set_lexers {

    my $lexer = shift;

    my ( $symbols, $symbol_hash, $QDFA, $tracing, $default_prefix,
        $default_suffix )
        = @{$grammar}[
        Marpa::Internal::Grammar::SYMBOLS,
        Marpa::Internal::Grammar::SYMBOL_HASH,
        Marpa::Internal::Grammar::QDFA,
        Marpa::Internal::Grammar::TRACING,
        Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
        ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh = $grammar->[Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_actions = $grammar->[Marpa::Internal::Grammar::TRACE_ACTIONS];
    }

    my @lexers;
    $#lexers = $#{$symbols};

    SYMBOL: for my $ix ( 0 .. $#lexers ) {

        my $symbol = $symbols->[$ix];
        my ( $name, $regex, $action, $symbol_prefix, $symbol_suffix ) =
            @{$symbol}[
            Marpa::Internal::Symbol::NAME,
            Marpa::Internal::Symbol::REGEX,
            Marpa::Internal::Symbol::ACTION,
            Marpa::Internal::Symbol::PREFIX,
            Marpa::Internal::Symbol::SUFFIX,
            ];

        if ( defined $regex ) {
            $lexers[$ix] = $regex;
            next SYMBOL;
        }

        my $prefix = $symbol_prefix // $default_prefix;
        if ( defined $prefix ) {
            $prefix = qr/$prefix/xms;
        }
        my $suffix = $symbol_suffix // $default_suffix;
        if ( defined $suffix ) {
            $suffix = qr/$suffix/xms;
        }

        given ($action) {
            when (undef) {;}    # do nothing
            when ('lex_single_quote') {
                $lexers[$ix] = [
                    \&Marpa::MDLex::Internal::Quotes::lex_single_quote,
                    $prefix, $suffix
                ];
            } ## end when ('lex_single_quote')
            when ('lex_double_quote') {
                $lexers[$ix] = [
                    \&Marpa::MDLex::Internal::Quotes::lex_double_quote,
                    $prefix, $suffix
                ];
            } ## end when ('lex_double_quote')
            when ('lex_q_quote') {
                $lexers[$ix] = [
                    \&Marpa::MDLex::Internal::Quotes::lex_q_quote, $prefix,
                    $suffix
                ];
            } ## end when ('lex_q_quote')
            when ('lex_regex') {
                $lexers[$ix] = [
                    \&Marpa::MDLex::Internal::Quotes::lex_regex, $prefix,
                    $suffix
                ];
            } ## end when ('lex_regex')
            default {
                Marpa::exception("Unknown lexer: $action");
            }
        } ## end given

        ##### assert: not $lexers[$ix] or $symbol->[Marpa'Internal'Symbol'TERMINAL]

    }    # SYMBOL

    return \@lexers;

}    # sub set_lexers

sub compile_regexes {
    my $lexer = shift;
    my ( $symbols, $default_lex_prefix, $default_lex_suffix, ) = @{$grammar}[
        Marpa::Internal::Grammar::SYMBOLS,
        Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
    ];

    SYMBOL: for my $symbol ( @{$symbols} ) {
        my $regex = $symbol->[Marpa::Internal::Symbol::REGEX];
        next SYMBOL if not defined $regex;
        if ( q{} =~ $regex ) {
            my $name = $symbol->[Marpa::Internal::Symbol::NAME];
            Marpa::exception( 'Attempt to add nullable terminal: ', $name );
        }
        my $prefix = $symbol->[Marpa::Internal::Symbol::PREFIX]
            // $default_lex_prefix;
        my $suffix = $symbol->[Marpa::Internal::Symbol::SUFFIX]
            // $default_lex_suffix;
        my $compiled_regex = qr{
            \G
            (?<mArPa_prefix>$prefix)
            (?<mArPa_match>$regex)
            (?<mArPa_suffix>$suffix)
        }xms;
        $symbol->[Marpa::Internal::Symbol::REGEX] = $compiled_regex;
    }    # SYMBOL

    return;

} ## end sub compile_regexes

# return values for text method
use Marpa::Offset qw(
    :package=Marpa::Recognizer
    PARSING_STILL_ACTIVE=-2
    PARSING_EXHAUSTED=-1
);

sub Marpa::Recognizer::text {
    my $recce        = shift;
    my $input        = shift;
    my $input_length = shift;

    return 0 if $recce->[Marpa::Internal::Recognizer::EXHAUSTED];

    Marpa::exception(
        'Marpa::Recognizer::text() third argument not yet implemented')
        if defined $input_length;

    my $input_ref;
    given ( ref $input ) {
        when (q{})      { $input_ref = \$input; }
        when ('SCALAR') { $input_ref = $input; }
        default {
            Marpa::exception( 'text argument to Marpa::Recognizer::text() ',
                'must be string or string ref' );
        }
    }    # given ref $input

    my $grammar = $recce->[Marpa::Internal::Recognizer::GRAMMAR];
    my $lexers  = $recce->[Marpa::Internal::Recognizer::LEXERS];
    my $phase   = $grammar->[Marpa::Internal::Grammar::PHASE];
    if ( $phase >= Marpa::Internal::Phase::RECOGNIZED ) {
        Marpa::exception('More text not allowed after end of input');
    }

    my $tracing = $grammar->[Marpa::Internal::Grammar::TRACING];
    my $trace_fh;
    my $trace_lex_tries;
    my $trace_lex_matches;
    if ($tracing) {
        $trace_fh = $grammar->[Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        $trace_lex_tries =
            $grammar->[Marpa::Internal::Grammar::TRACE_LEX_TRIES];
        $trace_lex_matches =
            $grammar->[Marpa::Internal::Grammar::TRACE_LEX_MATCHES];
    } ## end if ($tracing)

    my ( $symbols, $ambiguous_lex ) = @{$grammar}[
        Marpa::Internal::Grammar::SYMBOLS,
        Marpa::Internal::Grammar::AMBIGUOUS_LEX,
    ];

    $input_length //= length ${$input_ref};

    my $exhausted = 0;
    my $pos    = 0;
    my $lexables;

    pos ${$input_ref} = 0;
    POS: while ( $pos < $input_length ) {
        my @alternatives;

        # NOTE: Often the number of the earley set, and the idea of
        # lexical position will correspond.  Be careful that Marpa
        # imposes no such requirement, however.

        $lexables = $recce->[Marpa::Internal::Recognizer::CURRENT_LEXABLES];

        if ( $trace_lex_tries and scalar @{$lexables} ) {
            ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
            my $string_to_match = substr ${$input_ref}, $pos, 20;
            ## use critic
            $string_to_match
                =~ s/([\x00-\x1F\x7F-\xFF])/sprintf('{%#.2x}', ord($1))/gexms;
            say $trace_fh "Match target at $pos: ", $string_to_match;
        } ## end if ( $trace_lex_tries and scalar @{$lexables} )

        LEXABLE: for my $lexable ( @{$lexables} ) {
            my ($symbol_id) = @{$lexable}[Marpa::Internal::Symbol::ID];
            if ($trace_lex_tries) {
                print {$trace_fh} 'Trying to match ',
                    $lexable->[Marpa::Internal::Symbol::NAME], " at $pos\n"
                    or Marpa::exception('Could not print to trace file');
            }

            my $lexer      = $lexers->[$symbol_id];
            my $lexer_type = ref $lexer;
            Marpa::exception('Illegal type for lexer: undefined')
                if not defined $lexer_type;

            pos ${$input_ref} = $pos;

            if ( $lexer_type eq 'Regexp' ) {

                if ( ${$input_ref} =~ /$lexer/xmsg ) {

                    ## no critic (Variables::ProhibitPunctuationVars)
                    my $match = $+{mArPa_match};
                    ## use critic

                    # my $prefix = $+{mArPa_prefix};
                    # my $suffix = $+{mArPa_suffix};
                    # my $length = length(${^MATCH});

                    my $length = ( pos ${$input_ref} ) - $pos;
                    Marpa::exception(
                        'Internal error, zero length token -- this is a Marpa bug'
                    ) if not $length;
                    push @alternatives, [ $lexable, $match, $length ];
                    if ($trace_lex_matches) {
                        print {$trace_fh}
                            'Matched regex for ',
                            $lexable->[Marpa::Internal::Symbol::NAME],
                            " at $pos: ", $match, "\n"
                            or
                            Marpa::exception('Could not print to trace file');
                    } ## end if ($trace_lex_matches)
                    last LEXABLE if not $ambiguous_lex;
                }    # if match

                next LEXABLE;

            }    # if defined regex

            # If it's a lexable and a regex was not defined, there must be a
            # closure
            Marpa::exception("Illegal type for lexer: $lexer_type")
                if not $lexer_type eq 'ARRAY';

            my ( $lex_closure, $prefix, $suffix ) = @{$lexer};
            if ( defined $prefix ) {
                ${$input_ref} =~ /\G$prefix/xmsg;
            }

            my ( $match, $length ) = $lex_closure->( $input_ref, $pos );

            next LEXABLE if not defined $match;

            $length //= length $match;

            push @alternatives, [ $lexable, $match, $length ];
            if ($trace_lex_matches) {
                print {$trace_fh}
                    'Matched Closure for ',
                    $lexable->[Marpa::Internal::Symbol::NAME],
                    " at $pos: ", $match, "\n"
                    or Marpa::exception('Could not print to trace file');
            } ## end if ($trace_lex_matches)

            last LEXABLE if not $ambiguous_lex;

        }    # LEXABLE

        $pos++;
        if (not Marpa::Recognizer::earleme($recce, @alternatives ))
        {
            $recce->[Marpa::Internal::Recognizer::CURRENT_LEXABLES] = undef;
            $exhausted = 1;
            last POS;
        }

    }    # POS

    return
          $exhausted           ? Marpa::Recognizer::PARSING_EXHAUSTED
        : $pos < $input_length ? $pos
        :                        Marpa::Recognizer::PARSING_STILL_ACTIVE;

}    # sub text

# Always returns success
sub Marpa::Recognizer::end_input {
    Carp::croak('TO DO');
} ## end sub Marpa::Recognizer::end_input

1;

__END__

=pod

=head1 NAME

Marpa::MDLex - Marpa Demo Lexer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SUPPORT

See the L<support section|Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 LICENSE AND COPYRIGHT

Copyright 2007 - 2009 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5.10.0.

=cut
