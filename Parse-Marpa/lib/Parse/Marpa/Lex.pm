package Parse::Marpa;

use 5.010_000;

use warnings;
use strict;

# It's all integers, except for the version number
use integer;

# package for various lexing utilities
package Parse::Marpa::Lex;

# \x{5c} is backslash
sub gen_bracket_regex {
    my ($left, $right) = @_;
    qr/
        \G
        [^\Q$left$right\E\x{5c}]*
        (
              \Q$left\E
            | \Q$right\E
            | \x{5c}\Q$left\E
            | \x{5c}\Q$right\E
            | \x{5c}
        )
    /xms;
}

my %regex_data = (
    '{' => ['}', gen_bracket_regex('{', '}') ],
    '<' => ['>', gen_bracket_regex('<', '>') ],
    '[' => [']', gen_bracket_regex('[', ']') ],
    '(' => [')', gen_bracket_regex('(', ')') ],
);

# This is POSIX "punct" character class, except for backslash,
# and the right side bracketing symbols.
# hex 27 is single quote, hex 5b is the left square bracket.
my $punct = qr'[!"#$%&\x{27}(*+,-./:;<=?\x{5b}^_`{|~@]';

sub lex_q_quote {
    my $string = shift;
    my $start = shift;
    $$string =~ m/\Gqq?($punct)/ogc;
    my $left = $1;
    return unless defined $left;

    my $regex_data = $regex_data{$1};
    if (not defined $regex_data) {
        # \x{5c} is backslash
	my $regex
            = qr/
                \G
                [^\Q$left\E\x{5c}]*
                (
                     \Q$left\E
                    |\x{5c}\Q$left\E
                    |\x{5c}
                )
            /xms;
	$regex_data{$left} = $regex_data = [undef, $regex];
    }
    my ($right, $regex) = @$regex_data;
    # unbracketed quote
    if (not defined $right) {
	MATCH: while ($$string =~ /$regex/gc) {
	    next MATCH unless defined $1;
	    if ($1 eq $left) {
		my $length = (pos $$string) - $start;
		return (substr($$string, $start, $length), $length);
	    }
	}
	return;
    }

    # bracketed quote
    my $depth=1;
    MATCH: while ($$string =~ /$regex/g) {
	given ($1) {
           when (undef) { return }
	   when ($left) { $depth++; }
	   when ($right) { $depth--; }
	}
	if ($depth <= 0) {
	    my $length = (pos $$string) - $start;
	    return (substr($$string, $start, $length), $length);
	}
    }
    return;
}

sub lex_regex {
    my $string = shift;
    my $lexeme_start = shift;
    my $value_start = pos $$string;
    $$string =~ m{\G(qr$punct|/)}ogc;
    my $left_side = $1;
    return unless defined $left_side;
    my $left = substr($left_side, -1);
    my $prefix = ($left_side =~ /^qr/) ? "" : "qr";

    my $regex_data = $regex_data{$left};
    if (not defined $regex_data) {
        # \x{5c} is backslash
	my $regex
            = qr/
                \G
                [^\Q$left\E\x{5c}]*
                (
                     \Q$left\E
                    |\x{5c}\Q$left\E
                    |\x{5c}
                )
            /xms;
	$regex_data{$left} = $regex_data = [undef, $regex];
    }
    my ($right, $regex) = @$regex_data;
    # unbracketed quote
    if (not defined $right) {
	MATCH: while ($$string =~ /$regex/gc) {
	    next MATCH unless defined $1;
	    if ($1 eq $left) {
                # also take in trailing options
                $$string =~ /\G[msixpo]*/g;
                my $pos = pos $$string;
                return (
                    $prefix . substr($$string, $value_start, $pos - $value_start),
                    $pos - $lexeme_start
                );
	    }
	}
	return;
    }

    # bracketed quote
    my $depth=1;
    MATCH: while ($$string =~ /$regex/g) {
	given ($1) {
           when (undef) { return }
	   when ($left) { $depth++; }
	   when ($right) { $depth--; }
	}
	if ($depth <= 0) {
            # also take in trailing options
            $$string =~ /\G[msixpo]*/g;
            my $pos = pos $$string;
            return (
                $prefix . substr($$string, $value_start, $pos - $value_start),
                $pos - $lexeme_start
            );
	}
    }
    return;
}

1;    # End of Parse::Marpa

=head1 NAME

Parse::Marpa::Lex -- Utility Methods for Lexing

=head1 DESCRIPTION

These routines are used internally by MDL to implement lexing of regexes
and of C<q-> and C<qq->quoted strings.
They are documented here to make them available for general use within
Marpa.

=head1 METHODS

=head2 lex_regex

    my ($regex, $token_length)
        = Parse::Marpa::Lex::lex_regex(\$string, $lexeme_start)

Takes two required arguents, a I<string reference> and a I<start earleme>.
The I<string reference> must be to a string that may contain a regex.
The regex will be expected to start at the position pointed to by C<pos $$string>.

I<start_earleme> must be the start earleme of the regex for lexing purposes.
In many cases (such as the removal of leading whitespace), it's useful to discard
prefixes.
If a prefix was removed
prior to the call to C<lex_regex>,
I<start_earleme>
should be the location where the prefix started.
If no prefix was removed, I<start_earleme> will be the same as C<pos $$string>.

How C<lex_regex> delimits a regex is described in L<the MDL document|Parse::Marpa::Doc::MDL>.
C<lex_regex> returns the null array if no regex was found.
If a regex was found,
C<lex_regex> returns an array of two elements.
The first element is a string containing the regex,
its delimiters,
any postfix modifiers it had,
and its C<qr-> "operator" if there was one.
The second is the regex's length for lexing purposes,
which will include the length of any discarded prefix.

=head2 lex_q_quote

    my ($string, $token_length)
        = Parse::Marpa::Lex::lex_q_quote(\$string, $lexeme_start)

Takes two required arguents, a I<string reference> and a I<start earleme>.
The I<string reference> must be to a string that may contain a C<q-> or C<qq->quoted string.
The C<q-> or C<qq->quoted string will be expected
to start at the position pointed to by C<pos $$string>.

I<start_earleme> must contain the start earleme of the quoted string for lexing purposes.
In many cases (such as the removal of leading whitespace), it's useful to discard
prefixes.
If a prefix was removed
prior to the call to C<lex_regex>,
I<start_earleme>
should be the location where the prefix started.
If no prefix was removed, I<start_earleme> should be the same as C<pos $$string>.

How C<lex_q_quote> delimits a C<q-> or C<qq->quoted string is described in L<the MDL document|Parse::Marpa::Doc::MDL>.
C<lex_q_quote> returns the null array if no string was found.
If a string was found,
C<lex_q_quote> returns an array of two elements.
The first element is a string containing the C<q-> or C<qq->quoted string,
including the C<q-> or C<qq-> "operator" and the delimiters.
The second is the quoted string's length for lexing purposes,
which will include the length of any discarded prefix.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
