use 5.010_000;

package Parse::Marpa;

use warnings;
no warnings "recursion";
use strict;

BEGIN {
    our $VERSION = '0.205000';
    our $STRING_VERSION = $VERSION;
    $VERSION = eval $VERSION;
}

use integer;

use Parse::Marpa::Grammar;
use Parse::Marpa::Recognizer;
use Parse::Marpa::Parser;
use Parse::Marpa::Lex;

# Maybe it'll be optional someday, but not today
use Parse::Marpa::MDL;

=begin Apology:

The Coding Style of this Module,
Together with Some Thoughts about Coding Style in General

This is not my idea of a good, general Perl style.  But a single
coding style is not applicable in all cases.  The same coding style
quite adequate in a throw-away script would be terrible in code
intended for a critical production enviromment or maintainance
by a large, diversed staff.  The style of this module matches
its purpose, its likely future, and the likely resources for
maintaining it.

An important, but very non-standard, aim of this code is easy
translation into time-efficient C.  This is because parsers run
inside tight loops.  The rap against Earley's in particular has
always been speed.  Readability is not a good reason to write a
module that will never be used because it's too slow.

So I've written very C-ish Perl -- lots of references, avoidance
of hashes in the internals, no internal OO, etc., etc.  I don't
usually write Perl this way.  I don't think it's usually a good
idea to write Perl this way.  But as the lawyers say, circumstances
make cases.

C conversion is important because one of two things are going to
happen to Marpa: it turns out to be so slow it's difficult to use,
or it does not.  If Marpa is slow, the next thing to try is conversion
to C.  If it's fast, Marpa will be highly useful, and there will
almost certainly be demand for an even faster version -- in C++ or C.

Damian Conway's _Perl Best Practices_ is the best starting point
for thinking about Perl style, whether you agree with him or not.
I've made many exceptions due to necessity, as described above.
Many more I've no doubt made out of ignorance.  A few other exceptions
are because I can't agree with Damian.

An example of a deliberate exception I've made to Damian's guidelines:
I don't append "_ref" to the name references -- almost every variable
name in the below is a reference.  This may not be easy code to
read, but I can't believe having 90% of the variable names end in
"_ref" is going to make it any easier.  As Damian notes, his own
CPAN modules don't follow his guidelines all that closely.

=end Apology:

=cut

package Parse::Marpa::Internal;

use Carp;

our $compiled_eval_error;
BEGIN {
    eval "use Parse::Marpa::Source $Parse::Marpa::STRING_VERSION";
    $compiled_eval_error = $@;
    undef $Parse::Marpa::Internal::compiled_source_grammar
        if $compiled_eval_error;
}

package Parse::Marpa::Read_Only;

# Public namespace reserved for dynamic globals, that is local() variables,
# available to the user on a read only basis.
# No actual globals should reside here

package Parse::Marpa::Internal::This;

# Internal namespace reserved for dynamic globals, that is local() variables.
# No actual globals should reside here

package Parse::Marpa::Internal;

# Returns failure if no parses.
# On success, returns first parse in scalar context,
# all of them in list context.
sub Parse::Marpa::mdl {
    my $grammar = shift;
    my $text = shift;
    my $options = shift;

    my $ref = ref $grammar;
    croak(qq{grammar arg to mdl() was ref type "$ref", must be string ref})
        unless $ref eq "SCALAR";

    $ref = ref $text;
    croak(qq{text arg to mdl() was ref type "$ref", must be string ref})
        unless $ref eq "SCALAR";

    $options //= {};
    $ref = ref $options;
    croak(qq{text arg to mdl() was ref type "$ref", must be hash ref})
        unless $ref eq "HASH";

    my $g = new Parse::Marpa::Grammar(
        { mdl_source => $grammar, %{$options} }
    );
    my $recce = new Parse::Marpa::Recognizer({grammar => $g});

    my $failed_at_earleme = $recce->text($text);
    if ($failed_at_earleme >= 0) {
        die_with_parse_failure($text, $failed_at_earleme);
    }

    my $parser = new Parse::Marpa::Parser($recce);
    if (not defined $parser) {
        die_with_parse_failure($text, length($text));
    }
    my @values;
    push(@values, $parser->value());
    return $values[0] unless wantarray;
    push(@values, $parser->value()) while $parser->next();
    @values;
}

sub Parse::Marpa::show_value {
    my $value_ref = shift;
    my $ii        = shift;
    return "none" unless defined $value_ref;
    my $value = $$value_ref;
    return "undef" unless defined $value;
    if ($ii) {
        my $type = ref $value;
        return $type if $type;
    }
    return "$value";
}

=head1 NAME

Parse::Marpa - (Alpha) Earley's algorithm with LR(0) precomputation

=head1 VERSION

This is an Alpha release.
It's intended to let people look Marpa over and try it out.
Uses beyond that are risky.
While Marpa is in alpha,
you certainly don't want to use it for anything
mission-critical or with a serious deadline.

=cut

=head1 SYNOPSIS

    use 5.010_000;
    use strict;
    use warnings;
    use English;
    use Parse::Marpa;

    # remember to use refs to strings
    my $value = Parse::Marpa::mdl(
        (do { local($RS) = undef; my $source = <DATA>; \$source; }),
        \("2+2*3")
    );
    say $$value;

    __DATA__
    semantics are perl5.  version is 0.205.0.  start symbol is Expression.

    Expression: Expression, /[*]/, Expression.  priority 200.  q{
        $_->[0] * $_->[2]
    }.

    Expression: Expression, /[+]/, Expression.  priority 100.  q{
        $_->[0] + $_->[2]
    }.

    Expression: /\d+/.  q{ $_->[0] }.

=head1 DESCRIPTION

=head2 Capabilities

Marpa parses any language which can be expressed in BNF without infinite loops.
Marpa parses all "proper" context-free grammars, as well as those with empty
productions and useless productions.
In formal terms, Marpa parses any cycle-free context-free grammar.

Marpa cheerfully parses recursive grammars.
Grammars may be left-recursive, right-recursive, middle-recursive or all three,
so long as the recursion does not involve a cycle.

A cycle occurs when a BNF symbol can produce, directly or indirectly,
a string consisting of nothing but the original symbol.
Essentially, a cycle is recursion without change.
Unlike recursion, which is highly useful, cycles always seem to be pathological.

Empty productions are those with an empty right hand side.
Many useful languages
need empty productions to express their semantics clearly.
Marpa parses grammars with empty productions.

An ambiguous grammar is a grammar which might parse an input in more than one way.
Ambiguous grammars are a Marpa specialty.
Ambiguity is useful even when you are only interested in one parse.
An ambiguous grammar is often
the easiest and most sensible way to express a language.

Human languages are ambiguous.
English sentences often can mean more than one thing,
but human listeners hear the parse that makes most sense.
Marpa allows the user to prioritize rules
so that a preferred parse is returned first.
Marpa can also return all the parses of an ambiguous grammar,
if that's what the user prefers.

Marpa incorporates the latest academic research on Earley's algorithm,
combining it with LR(0) precomputation.
Marpa's own innovations
include predictive and ambiguous lexing.

=head2 The Easy Way

Most of Marpa's capabilities are available using a single static method:
L<C<Parse::Marpa::mdl>|/mdl>.
The C<mdl> method requires a grammar description in MDL (the Marpa Description Language) and a string.
C<mdl> parses the string according to the MDL description.
C<mdl> returns the result from evaluating the first parse in scalar context.
In list context, it returns all the results.

=head2 Semantic Actions

Marpa's semantics
are specified using Perl 5 code strings, called B<actions>.
Marpa allows lexing actions, a preamble action, rule actions and null symbol actions.

Actions are calculated in
a special namespace set aside for that purpose.
The preamble action is always run first
and can be used to initialize that namespace.

The result of an action is the result of Perl 5 code string.
For example,
from L<the synopsis/"SYNOPSIS">, here's a rule for an expression that does addition:

    Expression: Expression, /[+]/, Expression.

and here's its action:

    $_->[0] + $_->[2]

In rule actions, C<$_> is defined as a reference to an array of the values of the symbols
on the left hand side of the rule.

Marpa is targeted to Perl 6.
When Perl 6 is ready, Perl 6 code will become its default semantics.

=head2 Null Symbol Values

As mentioned, Marpa parses grammars with empty productions.
This means certain symbols in the grammar can result in nothing
or, saying the same thing more formally, can produce the empty string.

A B<null symbol> is a symbol which produces the empty string.
When a symbol produces the empty string it is said to be B<nulled>.
The value Marpa
assigns to an empty string is based
on the nulled symbol.

Even within a single parse, the same symbol may be nulled in some positions
but produce non-empty strings in other positions.
A symbol may be nulled directly, that is,
because is the right hand side of an empty production.
A symbol may be nulled indirectly if it produces other symbols,
but all of these are eventually nulled.

Every symbol which can be nulled has a B<null symbol value>,
or more briefly, B<null value>.
The default null value is a Marpa option (C<default_null_value>).
If not explicitly set, C<default_null_value> is a Perl 5 undefined.

Every symbol can have its own null symbol value.
The null symbol value for any symbol is calculated by running the action
specified for the empty rule which has that symbol as its left hand side.
For more details, including examples and a description of how null values are
calculated when a symbol is nulled indirectly, see L<Parse::Marpa::Parser/"Null Symbol Values">.

=head2 Tokens and Earlemes

   Summarize this section, focusing on mdl().

MDL is the easiest way to set up lexing in Marpa.
If you specify Perl 5 regexes for the terminals in your MDL source,
The Right Thing happens automatically.
Used this way, Marpa is easier than most parser generators.
Most parser generators can fail if tokens overlap,
or if your regexes allow more than one possible token stream.
Marpa allows ambiguous lexing by default.
Any multiple choices are passed up to its Earley-based parse engine
which is totally undaunted in the face of ambiguity.

Even if you wind up tracing the lexing,
Marpa's way of looking at the input is in some respects more natural than
conventional parsers.
Most parsers work with a token stream -- the lexer breaks the input string
into tokens and the parser works with tokens, not characters.
MDL lexing, because it must deal with variable length and potentially
overlapping tokens, keeps track of positions in the character stream.

Another convenience is that terminals can appear on the left hand side of rules without
causing Marpa any problems.
Most parsers have a problem with this.

While MDL's lexing works in terms of character positions,
Marpa is not restricted to this model.
Far from it.
Marpa's idea of parse position uses an abstraction I call an B<earleme>,
in recognition of Jay Earley.
Parsing starts at earleme zero, and proceeds upward through earleme 1, 2, etc.
B<Distance> or B<length> in earlemes are what they sound like.
The distance between earleme 10 and earleme 13 is 3 earlemes.
An token which begins at earleme 10 and ends at earleme 20 is 10 earlemes long.

Tokens cannot have a zero or negative length in earlemes.
Also, tokens have to be passed to the recognizer in increasing earleme order,
based on their start position.
Users are free to implement any input model that obeys these two
restrictions.

As mentioned, if you specify your lexing patterns with MDL, you will use a
one-character-per-earleme model.
You can feed Marpa an token stream, and use a one-token-per-earleme model to
imitate conventional parsing.
Advanced users can invent new models of the input,
customized to their own applications.
For more detail see L<Parse::Marpa::Grammar/"Tokens and Earlemes">.

=head2 Creating a Marpa Parser

When you're ready to create your first Marpa parser,
or curious about how that's done,
you should read the
L<Parse::Marpa::Doc::MDL> document, which
has the details on how to create an MDL grammar description.
That, and this document, should be enough to get started.

=head2 Phases

The C<mdl> method hides Marpa's parsing phases from the user,
calling Marpa's object methods as it needs to.
But for advanced applications and for tracing and diagnostics,
it is useful to how Marpa parses.

Marpa parsing take place in three phases:
grammar creation,
input recognition
and parsing proper.
Corresponding to the three phases
Marpa has three kinds of object: grammars, recognizers and parsers.
Recognizers are created from grammars and
parsers are created from recognizers.

Grammar objects (C<Parse::Marpa::Grammar>) are created first.
They may be created with rules or rules may be added to them.
When all the rules have been added,
the grammar is precomputed.
Details on grammar objects and methods can be found at L<Parse::Marpa::Grammar>.

In a strict sense, recognizing an input based on a grammar
and parsing an input based on that grammar are two different things.
Recognizing an input is merely answering "yes" or "no" to the question:
Does this input belong to the language described by the grammar?
Parsing that input means finding the structure of the string according to
the grammar.

Regular expressions, for example, do B<not> parse, strictly speaking.
They only recognize.
Perl 5 regexes are regular expressions with some extensions,
such as captures,
which can provide limited information about the structure of the input.
Most conventional parsers, such as C<yacc>, C<Parse::Yapp> or Perl 5's own parser,
have a separate lexing phase which is devoted to recognition.

Marpa has a separate recognition phase, separate from its proper parsing phase.
While recognizing its input, Marpa builds tables.
Marpa's proper parsing phase works from these tables.

To create a Marpa recognizer object (C<Parse::Marpa::Recognizer>),
a Marpa grammar object is required.
Once a recognizer object has been created, it can accept input.
Multiple recognizers can be created from a single grammar,
and they can safely be run simultaneously.
For more details on recognizer objects and methods,
see L<Parse::Marpa::Recognizer>.

Currently, Marpa fully supports only non-streaming or "offline" input.
Marpa can also parse streamed inputs,
but the methods to help finding completed parses in a streamed input 
are still very experimental.
In offline parsing, the parsing phase begins
with the creation of a Marpa parser object,
after input is complete.

Once a parser object (C<Parse::Marpa::Parser>) has been created from
a recognizer, a parse can be derived, its semantics run,
and its value returned.
In the case of an ambiguous grammar, there can be many parses, each
with its own value.
For details on parser objects and methods,
see L<Parse::Marpa::Parser>.

=head2 Grammar Interfaces

A grammar is specified to Marpa through a B<grammar interface>.
Right now there are only two grammar interfaces:
the B<Marpa Demonstration Language>
and the B<raw grammar interface>.

The B<raw grammar interface> is a set of named arguments to
the C<new> and C<set> methods of
Marpa grammar objects.
All other grammar interfaces use the raw grammar interface indirectly.
The raw grammar interface is efficient,
but higher-level interfaces are easier to read, write and maintain,
and even users seeking efficiency are usually better off
working at the higher level.
The documentation for the raw grammar interface
is L<Parse::Marpa::Doc::Raw>.

In Marpa's eyes all higher level grammar interfaces are equal.
I call the one that I am delivering with 
Marpa the B<Marpa Demonstration Language> instead
of the "Marpa Language" to emphasize it's lack of
special status.
The documentation for MDL can be found at L<Parse::Marpa::Doc::MDL>.
Users are encouraged to design their own
high-level Marpa interfaces.

=head2 Namespaces

For semantic actions and lexing closures,
there is a special namespace for each parse object,
which is entirely the user's.
In the following namespaces,
users should use only documented methods:

    Parse::Marpa
    Parse::Marpa::Grammar
    Parse::Marpa::Lex
    Parse::Marpa::MDL
    Parse::Marpa::Recognizer
    Parse::Marpa::Parser
    Parse::Marpa::Read_Only

Users should use the C<$_> variable and variables in the
the C<Parse::Marpa::Read_Only> namespace on a read-only basis.
Staying read-only can be tricky when dealing with Perl 5 arrays.
Be careful about auto-vivification!
If a Marpa namespace was not mentioned in this section,
users should not rely on or modify anything in it.

=head2 Returns and Exceptions

Most Marpa methods return only if successful.
On failure they throw an exception using C<croak()>.
If you don't want the exception to be fatal, catch it using C<eval>.
A few failures are considered "non-exceptional" and returned.
Non-exceptional failures are described in the documentation for the method which returns them.

=head2 The Status of this Module

Since this is alpha software, users with immediate needs must
look elsewhere.
I've no personal experience with them, but
C<Parse::Yapp> and C<Parse::RecDescent> are
alternatives to this module which are well reviewed and
more mature and stable.

Alpha versions may not be backward compatible.
MDL protects users by requiring the version to be specified,
and by insisting on an exact match with Marpa's version number.
This strict version regime is the same as that being considered for Perl 6.
Nonetheless, Marpa's version matching may become less strict once it goes beta.

=head1 METHODS

=head2 mdl

     # Parse a string and return the result
     # Be sure to specify both input and grammar as REFERENCES to strings
     $first_result = Parse::Marpa::mdl(\$grammar_description, \$string_to_parse);

     # if the parse is ambiguous and you want more than the first result,
     # return the value in array context
     @all_results = Parse::Marpa::mdl(\$grammar_description, \$string_to_parse);

     # You can set Marpa's options as named arguments, by specifying
     # a hash reference of them as the optional third argument
     $first_result = Parse::Marpa::mdl(
         \$grammar_description,
         \$string_to_parse,
         { warnings => 0 }
     );

The C<mdl> static method takes three arguments:
a B<reference> to a string containing an MDL description of the grammar;
a B<reference> to a string with the text to be parsed;
and (optionally) a B<reference> to a hash with options.

In scalar context,  C<mdl> returns a B<reference> to the value of the first parse.
In list context, C<mdl> returns a list of B<references> to the values of the parses.
If there are no parses, C<mdl> returns undefined in scalar context and
the empty list in list context.

=head2 Diagnostic Methods

L<A separate document on diagnostics|Parse::Marpa::Doc::Diagnostics> deals
with methods for debugging grammars and parses.

=head1 OPTIONS

Marpa has options which control its behavior.
These may be set using named arguments when C<Parse::Marpa::Grammar>
and C<Parse::Marpa::Recognizer>
objects are created,
with the C<Parse::Marpa::Grammar::set> method.

Ordinary Marpa options are listed and described below by argument name.
Options for debugging and tracing are dealt with in
L<the separate document on diagnostics|Parse::Marpa::Doc::Diagnostics>.

High level grammar interfaces have their own conventions
for Marpa options.
The documentation of MDL describes,
and the documentation of every high level interface should describe,
which options can be set through that interface, and how.

=over 4

=item ambiguous_lex

Treats its value as a boolean. 
If true, ambiguous lexing is used.
Ambiguous lexing means that even if a terminal is matched by a closure or a regex,
the search for other terminals at that location continues.
If multiple terminals match,
all the tokens found are considered for use in the parse.
If the parse is ambiguous,
it is possible that all the tokens will actually be used.
Ambiguous lexing is the default.

If false,
Marpa does unambiguous lexing,
which is the standard in parser generators.
With unambiguous lexing,
lexing at each location ends when the first terminal matches.
The user must ensure the first terminal to match is the correct one.
Traditionally, users have done this by making their
lex patterns deterministic --
that is,
they set their lex patterns
up in such a way that every valid input can be lexed in one and only one way.

Marpa offers users who opt for unambiguous lexing a second alternative.
Terminals are tested in order of priority, and the priorities can be set
by the user.

=item code_lines

If there is a problem with user supplied code,
Marpa prints the error message and a description of where the code is being used.
Marpa also displays the code.
The value of C<code_lines> tells Marpa how many lines to print before truncating the
code.
If it's zero, no code is displayed.
If it's negative, all the code is displayed, no matter how long it is.
The default is 30 lines.

=item default_action

Takes as its value a string, which is expected to be code in the current
semantics.
(Right now Perl 5 is the only semantics available.)
This value is used as the action for rules which have no
explicitly specified action.
If C<default_action> is not set,
the default action is to return a Perl 5 undefined.

=item default_lex_prefix

The value must be a regex in the current semantics.
(Right now Perl 5 is the only semantics available.)
The lexers allow every terminal to specify a B<lex prefix>,
a pattern to be matched and discarded before the pattern for
the terminal itself is matched.
Lex prefixes are often used to handle leading whitespace.

If a terminal has no lex prefix set, C<default_lex_prefix> is used.
When C<default_lex_prefix> is not set,
the default lex prefix is equivalent to a regex which always
and only matches the empty string.

=item default_null_value

The value must be an action, that is, a string containing code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The null value of a symbol is the symbol's value when it matches the empty string in a parse.

For symbols which do not have have a null symbol value set explicitly,
the null symbol value is calculated by
running the C<default_null_value>
action.
If C<default_null_value> is not set, the default null value is a Perl 5 undefined.
There's more about null values L<above|"Null Symbol Values"> and in
L<Parse::Marpa::Parser/"Null Symbol Values">.

=item online

A boolean.
If true, the parser runs in online mode.
If false, the parser runs in offline mode.

In B<offline> mode, which is the default,
Marpa assumes the input has ended when the first parse is requested.
It does some final bookkeeping,
refuses to accept any more input,
and sets its default parse to be a parse of the entire input,
from beginning to end.

In B<online> mode,
which is under construction and poorly tested,
new tokens may still be added,
and final bookkeeping is never done.
Marpa's default idea is still to parse the entire input up to the current earleme,
but in online mode that may not often be what the user wants.
If it's not, it up to her
to determine where to look for complete parses,
based on her knowledge of the structure of the grammar and the input.
The experimental method
L<Parse::Marpa::Recognizer::find_complete_rule|Parse::Marpa::Recognizer/find_complete_rule>
may help.

=item preamble

The preamble is a string which contains code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The preamble is run in a namespace special to the parse object.
Rule actions and lex actions also run in this namespace.
The preamble is run first, and may be used to set up globals.

If multiple preambles are specified as named arguments,
the more recent preambles replace any earlier ones.
This is consistent with the behavior of other named arguments,
but it differs from the behavior of MDL,
which creates a preamble by concatenating the code strings.

=item semantics

The value is a string specifying the type of semantics used in the semantic actions.
The current default, and the only available semantics at this writing, is C<perl5>.

=item trace_file_handle

The value is a file handle.
Warnings and trace output go to the trace file handle.
By default it's C<STDERR>.

=item version

If present, the C<version> option must match the current
Marpa version B<exactly>.
This is because while Marpa is in alpha,
features may change dramatically from version
to version.

=item volatile

The C<volatile> option is used to mark
a grammar or parse object as volatile or non-volatile.
Not specifying this option and accepting the default behavior is always safe.

A value of 1 marks the object volatile.
A value of 0 marks it non-volatile.
Parses inherit the volatility marking, if any, of the
grammar they are created from.
If a parse is created
from a grammar without a volatility marking,
and no volatility marking is specified when the parse is created,
the parse is marked volatile.

When a parse object is marked non-volatile,
an optimization called "node value memoization" is enabled.
Parses should only marked non-volatile only if
a parse object's semantic actions can be safely memoized.

If an object is marked volatile at any point in its history,
its volatility marking cannot be changed.
If the user tries to, he is probably making a dangerous mistake,
and Marpa throws an exception.
This exception is thrown even if the object was marked volatile by inheritance
from another object,
or by internal action on Marpa's part.
Marpa internally marks a grammar volatile, for example,
when the grammar uses certain kinds of sequence productions.
For more details,
see L<Parse::Marpa::Parser/"Volatility">.

=item warnings

The value is a boolean.
If true, it enables warnings
about inaccessible and unproductive rules in the grammar.
Warnings are written to the trace file handle.
By default, warnings are on.

Inaccessible rules are those which can never be produced by the start symbol.
Unproductive rules are those which no possible input could ever match.
Marpa ignores these, and if the remaining rules
specify a useable grammar will happily parse it.

Inaccessible and unproductive rules sometimes indicate errors in the grammar
design.
But a user may have plans for them,
may wish to keep them as notes,
or may simply wish to deal with them later.

=back

=head1 IMPLEMENTATION NOTES

Those experienced in Perl say that passing
string refs instead of strings is a pointless
and even counter-productive optimization.
I agree, but Marpa is an exception.
Marpa expects to process and output entire files,
some of which might be very long.

Use of object orientation in Marpa is superficial.
Only grammars, recognizers and parsers are objects, and they are not
designed to be inherited.

=head2 Speed

Speed seems very good for an Earley's implementation.
In fact, the current bottlenecks seem not to be in the Marpa parse engine, but
in the lexing, and in the design of the Marpa Demonstration Language.

=head3 Ambiguous Lexing

Ambiguous lexing has a cost, and grammars which can turn ambiguous lexing off
can expect to parse twice as fast.
Right now when Marpa tries to lex multiple regexes at a single location, it does
so using an individual Perl 5 regex match for each terminal, one after another.

There may be
a more efficient way to find all the matches in
a set of alternatives.
A complication is that
Marpa does predictive lexing, so that the list of lexables is
not known until just before the match is attempted.
But I believe that
lazy evaluation and memoizing could have big payoffs in the cases of most
interest.

=head3 The Marpa Demonstration Language

The Marpa Demonstration Language was
written to show off a wide range of Marpa's capabilities.
A high-level grammar interface written without this agenda
might easily run faster.

If MDL's parsing speed
becomes an issue with a particular grammar,
that grammar can be precompiled.
Subsequent runs from the precompiled grammar won't incur the overhead of either
MDL parsing or precomputation.

=head3 Comparison with other Parsers

In thinking about speed, it is helpful to
keep in mind Marpa's place in the parsing food chain.
Marpa parses many grammars that bison, yacc, L<Parse::Yapp>,
and L<Parse::RecDescent>
cannot parse.
For these, Marpa is clearly faster.  When it comes to time efficiency,
never is not hard to beat.

Marpa allows grammars to be expressed in their most natural form.
It's ideal where programmer time is important relative to running time.
Right now, special-purpose needs are often addressed with regexes.
This works wonderfully if the grammar involved is regular, but across
the Internet many man-years are being spent trying to shoehorn non-regular
grammars into Perl 5 regexes.

Marpa is a good alternative whenever
another parser requires backtracking.
Earley's parsers never need to backtrack.
They find every possible parse the first time through.
Backtracking is a gamble,
and one you often find you've made against the odds.

Some grammars have constructs to control backtracking.
To my mind this control comes at a high price.
Solutions with these constructs built into them are
about as close to unreadable as anything in the world of programming gets,
and fragile in the face of change to boot.

If you know you will be writing an LALR grammar or a regular one,
that is a good reason B<not> to use Marpa.
When a grammar is LALR or regular,
Marpa takes advantage of this and runs faster.
But such a grammar will run faster yet on a parser designed
for it:
bison, yacc and L<Parse::Yapp> for LALR; regexes
for regular grammars.

Finally, there are the many situations when we want to do some parsing as a one-shot
and don't want to have to care what subcategory our grammar falls in.
We want to write some quick BNF,
do the parsing,
and move on.
For this, there's Marpa.

=head1 DEPENDENCIES

Requires Perl 5.10.
Users who want or need the maturity and/or stability of Perl 5.8 or earlier
are probably also best off with more mature and stable alternatives to Marpa.

=head1 AUTHOR

Jeffrey Kegler

=head2 Why is it Called "Marpa"?

Marpa is the name of the greatest of the Tibetan "translators".  In
that time (we're talking the 11th century AD) Indian Buddhism was
at its height.  A generation of scholars was devoting
itself to producing Tibetan versions of Buddhism's Sanskrit scriptures.
Marpa was their major figure, and today he is known simply as Marpa
Lotsawa: "Marpa the Translator".

In the 11th century, translation was not a job for the indoors type.
A translator needed to study with the teachers who had the
texts and could explain them.  That meant going to India.
Getting to India from Marpa's home in the Lhotrak Valley
meant crossing two hundred difficult and lawless miles to
Khala Chela Pass,
and scaling its three-mile high summit.

From Khala Chela to the great Buddhist center of Nalanda
University was four hundred miles and downhill,
but Tibetans would stop off for years or months in Nepal.
Tibetans had learned
the hard way
to take some time to get used to low altitude
instead of going straight to Nalanda.
Whole expeditions had
died from disease within weeks of arrival on the hot plains.
Almost no germs live in the cold,
thin air of Tibet,
and Tibetans arriving
directly in the lowlands had no immunities.

=head2 Blatant Plug

There's more about Marpa in my new novel, B<The God Proof>, in which
his studies, travels and adventures are a major subplot.  B<The God
Proof> centers around Kurt GE<ouml>del's proof of God's existence.
Yes, I<that> Kurt GE<ouml>del, and yes, he really did work out a
God Proof (it's in his I<Collected Works>, Vol. 3, pp. 403-404).
B<The God Proof> is available
as a free download L<http://www.lulu.com/content/933192>,
and in print form at Amazon.com:
L<http://www.amazon.com/God-Proof-Jeffrey-Kegler/dp/1434807355>.

=head1 TO DO

See L<Parse::Marpa::To_Do>.

=head1 BUGS

=head2 Priority Conflicts

If non-default priorities are given to rules, it's possible two rules
with different priorities could wind up in the same SDFA state.
Marpa can't proceed when that happens.
(See the L<internals document|Parse::Marpa::Doc::Internals> if you're
interested in the details about SDFA's.)

I've actually never seen this happen, and one reason the problem is
not fixed is that I will need to contrive a case where the problem occurs.
Otherwise, I can't test the fix.
But if you're the unlucky first person to encounter this, here are
the workarounds.

Workaround 1:
Marpa will report the rules which caused the conflict.
If they can be changed to have the same priority, the problem is
solved.

Workaround 2:
Instead of using priorities, use multiple parses.
That is, instead of using priorities to make the desired parse first
in order, allow the "natural" order and iterate through the parses
until you get the one you want.

Workaround 3:
Make a small change in the grammar.
Be aware that the code which creates the SDFA is smart enough that you'll
probably need to make some sort of 
real change to the target language.
Simply writing different rules with the same effect probably won't make
the problem go away.

I believe there's a fix to this problem,
but it will require some mathematics.
Here's what I think is the fix:
Change the SDFA to be a little more non-deterministic,
so that there are different SDFA nodes for the different priorities,
with empty transitions between them.
(Aren't you sorry you asked?)

With a fix of this kind,
testing examples (even if they were easier to find) is not sufficient to show correctness.
I'll need to show that the current and the fixed SDFA's are "equivalent".
That demonstration may need to be a mathematical proof.
For now, there's the comfort that the problem seems to be quite rare.

=head2 Non-intuitive Parse Order in Unusual Cases

This problem occurs when

=over 4

=item * An ambiguous production has more than two nullable symbols on the right hand side; and

=item * The semantics are such that order of the parses for that production matters.

=back

This doesn't happen in any practical grammars I've tried.
Perhaps it's a unnatural way to set up the semantics.
But it certainly does happen in textbook grammars.

A very straightforward workaround is described below.
But the problem needs to be fixed, certainly before Marpa goes beta.

Details: The problem occurs because these productions are rewritten internally by CHAF.
A rightmost parse comes first as I have documented,
but it is a rightmost parse for the grammar B<as rewritten by CHAF>.
This is a bug for pendantic reasons, because
CHAF rewriting is supposed to be invisible.
It's a bug for practical reasons because the CHAF-driven order is not intuitive,
and I can't picture it ever being the desired first choice.
Priorities are B<not> a workaround, because priorites cannot be set for rules
within a CHAF rewrite.

Workaround:
Rewrite the rule for which this is a problem.
The problem only
occurs where a rule is subject to CHAF rewriting,
and CHAF rewrites are only done to rules with more than two nullables on the right hand side.
It is always possible to break up a
rule into other rules such that at most two nullables occur on the right hand side.

=head2 What!  You Found Even More Bugs!

Please report any bugs or feature requests to
C<bug-parse-marpa at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Marpa>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Marpa
    
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Marpa>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Marpa>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Marpa>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Marpa>

=back

=head1 ACKNOWLEDGMENTS

Marpa is
the parser described in
L<Aycock and Horspool 2002|Parse::Marpa::Doc::Bibliography/"Aycock and Horspool 2002">.
I've made significant changes to it,
which are documented separately (L<Parse::Marpa::Doc::Algorithm>).
Aycock and Horspool, for their part,
built on the
L<algorithm discovered by Jay Earley|Parse::Marpa::Doc::Bibliography/"Earley 1970">.

I'm grateful to Randal Schwartz for his encouragement over the years that
I've been working on Marpa.  My one conversation
with Larry Wall
about Marpa
was brief and long ago, but his openness to the idea is a major
encouragement,
and his insights into how humans do programming,
how they do languages,
and how those two endeavors interconnect,
a major influence.
More recently,
Allison Randal and Patrick Michaud have been generous with their
very valuable time.
They might have preferred that I volunteered as a Parrot cage-cleaner,
but if so, they were too polite to say so.

Many at perlmonks.org answered questions for me.
Among others, I used answers from
chromatic, dragonchild, samtregar and Juerd
in the writing this module.
I'm equally grateful to those whose answers I didn't use.
My inquiries were made while I was thinking out the code and
it wasn't always 100% clear what I was after.
If the butt is moved after the round,
it shouldn't count against the archer.

In writing the Pure Perl version of Marpa, I benefited from studying
the work of Francois Desarmenien (C<Parse::Yapp>), 
Damian Conway (C<Parse::RecDescent>) and
Graham Barr (C<Scalar::Util>).
Adam Kennedy patiently corrected me on the finer points of module writing,
as well as about some issues where I really should have know better.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jeffrey Kegler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Parse::Marpa

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
