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
sub Parse::Marpa::marpa {
    my $grammar = shift;
    my $text = shift;
    my $options = shift;

    my $ref = ref $grammar;
    croak(qq{grammar arg to marpa() was ref type "$ref", must be string ref})
        unless $ref eq "SCALAR";

    $ref = ref $text;
    croak(qq{text arg to marpa() was ref type "$ref", must be string ref})
        unless $ref eq "SCALAR";

    $options //= {};
    $ref = ref $options;
    croak(qq{text arg to marpa() was ref type "$ref", must be hash ref})
        unless $ref eq "HASH";

    my $g = new Parse::Marpa::Grammar(
        source => $grammar,
        %{$options}
    );
    my $recce = new Parse::Marpa::Recognizer(grammar => $g);

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
    my $value = Parse::Marpa::marpa(
        (do { local($RS) = undef; my $source = <DATA>; \$source; }),
        \("2+2*3")
    );
    say $$value;

    __DATA__
    semantics are perl5.  version is 0.205.0.  start symbol is Expression.

    Expression: Expression, /[*]/, Expression.  priority 200.  q{
        $Parse::Marpa::Read_Only::v->[0] * $Parse::Marpa::Read_Only::v->[2]
    }.

    Expression: Expression, /[+]/, Expression.  priority 100.  q{
        $Parse::Marpa::Read_Only::v->[0] + $Parse::Marpa::Read_Only::v->[2]
    }.

    Expression: /\d+/.  q{ $Parse::Marpa::Read_Only::v->[0] }.

=head1 DESCRIPTION

C<Parse::Marpa> parses any cycle-free context-free grammar.

=over 4

=item *

Marpa parses any grammar which can be specified in cycle-free BNF.
(A cycle is a case where A produces A -- the BNF version of an infinite loop.)

=item *

The ban on cycles is B<not> a ban on recursion.
Marpa cheerfully parses left-recursive, right-recursive
and any other kind of recursive grammar, so long as it is cycle-free.
Recursion is useful.  Cycles (which are essentially recursion without change)
seem to always be pathological.

=item *

Marpa parses grammars with empty productions.
Empty productions are often important in specifying semantics.

=item *

Ambiguous grammars are a Marpa specialty.
They are useful even if you only want one parse.
An ambiguous grammar is often
the easiest and most sensible way to express a language.
Human languages are ambiguous.
We listen and pull out the parse that makes most sense.
Marpa allows the user to prioritize rules
so that a preferred parse comes up first.

=item *

Marpa can also return all the parses of an ambiguous grammar.

=item *

Marpa incorporates the latest academic research on Earley's algorithm,
combining it with LR(0) precomputation.

=item *

Marpa's own innovations
include predictive and ambiguous lexing.

=back

=head2 The Status of this Module

This is an alpha release.
See the warnings L<above|"VERSION">.
Since this is alpha software, users with immediate needs must
look elsewhere.
I've no personal experience with them, but
C<Parse::Yapp> and C<Parse::RecDescent> are
alternatives to this module which are well reviewed and
much more mature and stable.

There will be bugs and misfeatures when I go alpha,
but all known bugs will be documented
have workarounds.
The documentation follows the industry convention of telling the
user how Marpa should work.
If there's a known difference between that and how Marpa actually works,
it's in L<the Bugs section|/"BUGS AND MISFEATURES">.
You'll want to at least skim that section
before using Marpa.

While Marpa is in alpha,
you may not want to automatically upgrade
as new versions come out.
Versions will often be incompatible.
MDL emphasizes this by requiring the C<version> option, and insisting
on an exact match with Marpa's version number.
That's a hassle, but so is alpha software.
The version number regime will become less harsh before Marpa
leaves beta.

=head2 Reading these Documents

L<Parse::Marpa::Doc::Concepts> should be read before
using Marpa, in fact probably before your first careful reading of this document.
The "concepts" in it are all practical
-- the theoretical discussions went
into L<Parse::Marpa::Doc::Algorithm>.
Even experts in Earley parsing will want to skim L<Parse::Marpa::Doc::Concepts>
because,
as one example,
the availability of ambiguous lexing has unusual implications for term I<token>.

L<Parse::Marpa::Doc::MDL> documents what is currently
Marpa's only high-level interface.
Of Marpa's current documents,
it is the most tutorial in approach.

=head1 METHODS

=head2 marpa(I<grammar>, I<text_to_parse>, I<option_hash>)

The C<marpa> method takes three arguments:
a B<reference> to a string containing a Marpa source description of the grammar in
one of the high-level interfaces;
a B<reference> to a string with the text to be parsed;
and (optionally) a B<reference> to a hash with options.

In scalar context,  C<marpa()> returns the value of the first parse if there was one,
and undefined if there were no parses.
In list context, C<marpa()> returns a list of references to the values of the parses.
This is the empty list if there were no parses.

The description referenced by the I<grammar> argument must use
one of the high-level Marpa grammar interfaces.
Currently the default (and only) high-level grammar interface is the
L<Marpa Demonstration Language|Parse::Marpa::Doc::MDL>.

=head2 Diagnostic Methods

L<The separate document on diagnostics|Parse::Marpa::Doc::Diagnostics> deals
with methods used primarily to debug grammars and parses.

=head1 OPTIONS

This section documents
the options recognized by the
C<Parse::Marpa::Grammar::new>,
C<Parse::Marpa::Recognizer::new>,
and C<Parse::Marpa::Grammar::set> methods.
When the same option is specified in two different method calls,
the most recent overrides any previous setting, unless
stated otherwise in the description of the option.

Most options set Marpa's predefined variables,
which can also be set using the high-level grammar interfaces.
A few options don't deal with Marpa's predefined variables
and are special to the C<new()> and C<set()> methods.
These "method only" options are documented in this section.

The options which set Marpa's predefined variables are documented in
L<the section on predefineds|/"PREDEFINEDS"> below,
except for those primarily used to
debug and trace grammars and parses.
Options for debugging and tracing are dealt with in
L<the separate document on diagnostics|Parse::Marpa::Doc::Diagnostics>.

=over 4

=item grammar

Takes as its value a grammar object.
Only valid as an option to
C<Parse::Marpa::Recognizer::new()>,
where it's required.

=item source

This takes as its value a B<reference> to a string containing a description of
the grammar in the L<Marpa Demonstartion Language|Parse::Marpa::Doc::MDL>.
It must be specified before any rules are added,
and may be specified at most once in the life of a grammar object.

=back

=head1 PREDEFINEDS

This section documents Marpa's predefined variables.
There are two ways to set these.
The most basic is as
B<method options>:
options of the 
C<Parse::Marpa::new()>,
C<Parse::Marpa::Recognizer::new()>,
and C<Parse::Marpa::set()> methods.
The other way to set them is as
B<high-level interface options>:
indirectly through one of
Marpa's high-level grammar interfaces.

This section discusses those semantics of Marpa's predefineds
which are the same across all interfaces;
as well as considerations specific to setting predefineds as
method options.
The canonical name of a Marpa predefined variable
is the same as the option name of its method option.

High level grammar interfaces are free to use
their own conventions
for dealing with Marpa's predefined variables.
The documentation of MDL describes,
and the documentation of every high level interface should describe,
which predefineds can be set through that interface,
how they are set,
and any special considerations that apply when using that high-level
interface.

Unless documented otherwise,
a predefined can be specified more than once.
The most recent setting always applies, again unless
documented otherwise.

A special case is when the same predefined is set twice in
the same method call,
once in high-level source provided as the value of C<source> method option,
and once directly through the predefined's own method option.
In that circumstance,
the method option's setting is always considered to be "more recent".
This mean that,
if the Marpa predefined variable has the default behavior,
which is for a "more recent" setting to override a "less recent" one,
the method option will override any settings in the high-level source.

=over 4

=item ambiguous_lex

Treats its value as a boolean. 
If true, ambiguous lexing is used.
This means that even if a terminal is matched by a closure or a regex,
the search for other terminals at that location continues.
If multiple terminals match,
all the tokens found are considered for use in the parse.
If the parse is ambiguous,
they may all end up actually being used.
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
The order in which terminals are tested can be manipulated by setting their priorities.

=item code_lines

If there is a problem with user supplied code,
Marpa prints the error message and a description of where the code is being used.
Marpa will display the code itself as well.
The value of this option tells Marpa how many lines to print before truncating the
code.
If it's zero, no code is displayed.
If it's negative, all the code is displayed, no matter how long it is.
The default is 30 lines.

=item default_action

Takes as its value a string, which is expected to be code in the current
semantics.
(Right now Perl 5 is the only semantics available.)
For rules which don't have an explicitly specified action,
the default is to return a Perl 5 undefined.
This default is usually adequate, but it
can be changed by setting the C<default_action> predefined.

=item default_lex_prefix

The value must be a regex in the current semantics.
(Right now Perl 5 is the only semantics available.)
The lexers allow every terminal to specify a B<lex prefix>,
a pattern to be matched and discarded before the pattern for
the terminal itself is matched.
This is typically used to handle leading whitespace.

The default is no lex prefix.
But whitespace processing is often wanted, and when it is,
the same whitespace processing is usually wanted for most or all terminals.
This can be done conveniently by changing the default lex prefix.

=item default_null_value

The value must be a string containing code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The null value of a symbol is its value when it matches the empty string in a parse.
By default, that value is a Perl 5 undefined.
Resetting the C<default_null_value> Marpa predefined resets that default.
There's more about null values in
L<the Concepts document|Parse::Marpa::Doc::Concepts>.

=item online

A boolean.
If true, the parser runs in B<online> mode.
If false, the parser runs in B<offline> mode.

In offline mode, which is the default,
Marpa assumes the input has ended when the first parse is requested.
It does some final bookkeeping,
refuses to accept any more input,
and sets its default parse to be a parse of the entire input,
from beginning to end.

In online mode,
which is under construction and poorly tested,
new tokens may still be added,
and final bookkeeping is never done.
Marpa's default idea is still to parse the entire input up to the current earleme,
but in online mode that is often not be what the user wants.
If it's not, it up to her
to determine the right places to look for complete parses,
based on her knowledge of the structure of the grammar and the input.
The method C<Parse::Marpa::Recognizer::find_complete_rule()>,
documented L<as a diagnostic method|Parse::Marpa::DIAGNOSTIC>, may help.

=item preamble

The preamble is a string which contains code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The preamble is run in a namespace special to the parse object.
Rule actions and lex actions also run in this namespace.
The preamble is run first, and may be used to set up globals.

If multiple preambles are specified as method options, the most
recent replaces any previous ones.
This is consistent with the behavior of other method options,
but different from the MDL, in which preambles are concatenated.

=item semantics

The value is a string specifying the type of semantics used in the semantic actions.
The only available semantics at this writing is C<perl5>.

=item trace_file_handle

The value is a file handle.
Warnings and trace output go to the trace file handle.
By default it's STDERR.

=item version

If present, the C<version> option must match the current
Marpa version B<exactly>.
This is because while Marpa is in alpha,
features may change dramatically from version
to version and
little effort will be devoted
to keeping the evolving versions compatible with
each other.
This version regime will be relaxed
by the time Marpa leaves beta.

=item volatile

The C<volatile> option is used to mark
a grammar or parse object as volatile or non-volatile.
Not specifying this option and accepting the default behavior is always safe.

A value of 1 marks the object volatile.
A value of 0 marks it non-volatile.
Parses inherit the volatility marking, if any, of the
grammar they are created from.
If a parse is created from a grammar without a volatility marking,
and none is specified when the parse is created,
the parse is marked volatile.

When a parse object is marked non-volatile,
an optimization called "node value memoization" is enabled.
Parses should only marked non-volatile only if
a parse object's semantic actions can be safely memoized.

If an object is ever marked volatile,
unsetting it back to non-volatile is almost certainly a dangerous oversight.
Marpa throws an exception if you do that.
For this purpose a grammar and the parse created from it are considered
to be the same object.

The "volatility unsetting exception" will be thrown even
if Marpa marked the grammar volatile internally.
Marpa often does this when a grammar has sequence productions.
For more details,
see L<Parse::Marpa::Doc::Concepts>.

=item warnings

The value is a boolean.
If true, it enables warnings
about inaccessible and unproductive rules in the grammar.
Warnings are written to the trace file handle.
By default, warnings are on.

Inaccessible rules are those which can never be produced by the start symbol.
Unproductive rules are those which no possible input could ever match.
Marpa is capable of simply ignoring these, if the remaining rules
specify a useable grammar.

Inaccessible and unproductive rules sometimes indicate errors in the grammar
design.
But a user may have plans for them,
may wish to keep them as notes,
or may simply wish to look at them at another time.

=back

=head1 IMPLEMENTATION NOTES

=head2 Namespaces

For semantic actions and lexing closures,
there is a special namespace for each parse object,
which is entirely the user's.
In the following namespaces,
users should use only documented methods:

    Parse::Marpa
    Parse::Marpa::Lex
    Parse::Marpa::MDL
    Parse::Marpa::Recognizer
    Parse::Marpa::Parser

In the C<Parse::Marpa::Read_Only> namespace,
users should used only documented variables,
and those on a read-only basis.
(Staying read-only can be tricky when dealing with Perl 5 arrays.
Be careful about auto-vivification!)
If a Marpa namespaces is not mentioned in this section,
users should not rely on or modify anything in it.

=head2 String References

Those experienced in Perl say that passing
string refs instead of strings is a pointless
and even counter-productive optimization.
I agree, but C<Marpa> is an exception.
Marpa expects to process and output entire files,
some of which might be very long.

=head2 Object Orientation

Use of object orientation in Marpa is superficial.
Only grammars and parses are objects, and they are not
designed to be inherited.

=head2 Returns and Exceptions

Most Marpa methods return only if successful.
On failure they throw an exception using C<croak()>.
If you don't want the exception to be fatal, catch it using C<eval>.
A few failures are considered "non-exceptional" and returned.
Non-exceptional failures are described in the documentation for the method which returns them.

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
a more efficient way to use Perl 5 regexes to find all matches in
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

As a reminder,
if the MDL's parsing speed
becomes an issue with a particular grammar,
that grammar can be precompiled.
Subsequent runs from the precompiled grammar won't incur the overhead of either
MDL parsing or precomputation.

=head3 Parsers and Speed, in general

In thinking about speed, it's helpful to be 
keep in mind Marpa's position in the hierarchy of parsers.
Marpa parses many grammars which bison, yacc, L<Parse::Yapp>,
and L<Parse::RecDescent>
cannot.
For these, it's clearly faster.  When it comes to time efficiency,
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
To my mind this control comes at a very high price.
Solutions with these controls built into them are
about as close to unreadable as anything in the world of programming gets,
and fragile in the face of change to boot.

If you know you will be writing an LALR grammar or a regular one,
it is a good reason B<not> to use Marpa.
When a grammar is LALR or regular,
Marpa takes advantage of this and runs faster.
But such a grammar will run faster yet on a parser designed
for it:
bison, yacc and L<Parse::Yapp> for LALR; regexes
for regular grammars.

Finally, there are the many situations when we need to do some parsing as a one-shot
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

=head2 Why is the Module named "Marpa"?

Marpa is the name of the greatest of the Tibetan "translators".  In
that time (we're talking the 11th century AD) Indian Buddhism was
at its height.  A generation of Tibetan translators were devoting
themselves to producing Tibetan versions of Buddhism's Sanskrit scriptures.
Marpa was their major figure, and today he is known simply as Marpa
Lotsawa: "Marpa the Translator".

In the 11th century, translation was not a job for the indoors type.
A translator needed to study with the teachers who had the
texts and could explain them.  That meant going to India.  Marpa's
home was in the Lhotrak Valley.
The route from the Lhotrak to India was via the three-mile high Khala Chela Pass,
two hundred difficult and lawless miles away.

From Khala Chela to the great Buddhist center of Nalanda
University was four hundred miles downhill,
but Tibetans would stop off for years or months in Nepal,
getting used to the low altitudes.
Tibetans had learned
not to go straight to Nalanda the hard way.
Almost no germs live in the cold,
thin air of Tibet,
and Tibetans arriving
directly in the lowlands had no immunities.
Whole expeditions had
died from disease within weeks of arrival on the hot plains.

=head2 Blatant Plug

There's more about Marpa in my new novel, B<The God Proof>, in which
his studies, travels and adventures are a major subplot.  B<The God
Proof> centers around Kurt GE<ouml>del's proof of God's existence.
Yes, I<that> Kurt GE<ouml>del, and yes, he really did work out a
God Proof (it's in his I<Collected Works>, Vol. 3, pp. 403-404).
B<The God Proof> is available at Amazon:
L<http://www.amazon.com/God-Proof-Jeffrey-Kegler/dp/1434807355>.

=head1 BUGS AND MISFEATURES

=head2 A More Exhaustive Test Suite

Testing has been intensive, but not exhaustive.
The parse engine has been very well exercised, but many combinations
of options and features have yet to be tried.
To get an idea for what's been well tested,
look in the C<t>, or test, directory of the distribution.
Any feature not tested there can be assumed
to have been only lightly exercized.

=head2 Options Code Poorly Organized

Most options are only valid at certain points in the parsing,
but this is haphazardly enforced and poorly documented.
There may be some just plain ol' bugs.
The options code needs to be cleaned up,
and the documentation tightened up.

=head2 Priority Conflicts

If non-default priorities are given to rules, it's possible two rules
with different priorities could wind up in the same SDFA state.
I won't explain the details of SDFA's here,
(see the L<internals document|Parse::Marpa::Doc::Internals>),
but Marpa can't proceed when that happens.

I've actually never seen this happen, and one reason the problem is
not fixed is that I need to contrive a case where the problem occurs
before I make a fix.  Otherwise, I can't test the fix.
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
Be aware that the code which creates the SDFA is smart enough so that you'll
probably need to make some sort of 
real change to the target language.
Simply writing different rules with the same effect probably won't make
the problem go away.

I believe there's a fix to this problem,
but it will require not only concocting a way to make the problem occur,
but at least a bit of mathematics.
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

=item * The semantics are such that order of the parses in that production matters.

=back

This doesn't happen in any practical grammars I've tried.
Perhaps it's a unnatural way to set up the semantics.
But it certainly happens in textbook grammars.

There is a very straightforward workaround, described below.
But the problem needs to be fixed, certainly before Marpa goes beta.

Details: The problem occurs because these productions are rewritten internally by CHAF.
A rightmost parse comes first as I have documented,
but it is a rightmost parse for the grammar B<as rewritten by CHAF>.
This is a bug for pendantic reasons, because
CHAF rewritting is supposed to be invisible.
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

=head2 Priorities Cannot Be Set in MDL for Terminals

Priorities cannot be set in MDL for terminals.
Fix this before going beta.

Workaround:
Add extra rules with the terminals you want to prioritize on their right hand side,
and assign 
priorities to the rules.

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
