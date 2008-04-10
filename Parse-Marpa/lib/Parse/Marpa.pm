use 5.010_000;

package Parse::Marpa;

use warnings;
no warnings "recursion";
use strict;

BEGIN {
    our $VERSION = '0.207_004';
    our $STRING_VERSION = $VERSION;
    $VERSION = eval $VERSION;
}

use integer;

use Parse::Marpa::Grammar;
use Parse::Marpa::Recognizer;
use Parse::Marpa::Evaluator;
use Parse::Marpa::Lex;

# Maybe MDL will be optional someday, but not today
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

    my $evaler = new Parse::Marpa::Evaluator($recce);
    if (not defined $evaler) {
        die_with_parse_failure($text, length($text));
    }
    return $evaler->next if not wantarray;
    my @values;
    while (defined(my $value = $evaler->next())) {
        push(@values, $value);
    }
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

=begin for_developer_releases:

 =urnq1 ORJNER: GUVF ERYRNFR VF SBE QRIRYBCREF BAYL

Guvf vf n qrirybcre'f eryrnfr, abg sbe hfr ol aba-qrirybcref.
V hfr gurfr eryrnfrf gb ninvy zlfrys bs gur pcnagrfgref erfhygf,
naq gb grfg gur eryrnfr cebprff vgfrys.

Bs pbhefr, vg'f bcra fbhepr, naq lbh'er ragvgyrq gb nccbvag lbhefrys
n qrirybcre vs lbh vafvfg ba vg.  Ohg gung jvyy hfhnyyl abg or n ernfbanoyr
guvat gb qb.

=end for_developer_releases:

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

=head2 Status

B<This is an Alpha release.
It's intended to let people look Marpa over and try it out.
Uses beyond that are risky.
While Marpa is in alpha,
you don't want to use it for anything
mission-critical or with a serious deadline.>
I've no personal experience with them, but
C<Parse::Yapp> and C<Parse::RecDescent> are
alternatives to this module which are well reviewed and
more mature and stable.

=head2 What Marpa can do

Marpa parses any language which can be written in BNF.
Marpa handles all proper context-free grammars,
plus those with empty rules,
inaccessble rules and unproductive rules.
Marpa parses left- and right-recursive grammars and ambiguous grammars.

Marpa's parses all context-free grammars, with one restriction.
Currently the grammar must be written so that it is cycle-free.
A cycle is a special, pathological case of recursion --
recursion without change.
A cycle happens when applying the rules of the grammar to a symbol results in
exactly that same symbol.
I may lift the restriction on cycles in future versions,
but grammars with cycles seem to have no advantages in convenience
or expressiveness.
The main gain from extending Marpa to parse grammars with cycles would be bragging rights
-- Marpa could then be able to say that it parses
anything you can write in BNF, with no restrictions whatsoever.

Empty productions are often necessary to express a language in a natural way.
Inaccessible rules and unproductive rules aren't useful, but they cause no
real harm.

Ambiguous grammars are a Marpa specialty.
(An ambiguous grammar is a grammar which might can parse an input in more than one way.)
Ambiguity is often useful even if you are only interested in one parse.
An ambiguous grammar is often
the easiest and most sensible way to express a language.

Human languages are ambiguous.
English sentences are often ambiguous,
but human listeners hear the parse that makes most sense.
Marpa allows the user to prioritize rules
so that a preferred parse is returned first.
Marpa can also return all the parses of an ambiguous grammar,
if that's what the user prefers.

Marpa incorporates major improvements from recent research into Earley's algorithm.
In particular, it combines Earley's with LR(0) precomputation.
Marpa also has innovations of its own,
including predictive and ambiguous lexing.

=head2 Parsing Terminology

The Marpa documents assume that you know
the standard concepts and terminology of parsing.
This section is intended to be read quickly to serve as a reminder.
I put B<defining uses> of terms in boldface, for easy skimming.
If you are already comfortable with parsing terminology,
you could skip this section entirely.

This terse summary of the vocabulary
is aimed at those who are
mostly familiar with it already.
If you aren't, it's probably not a good idea to try
to learn the basics of parsing here.
As an introduction, I reccommend
L<Mark Jason Dominus's
excellent chapter on parsing in the Perl context|Parse::Marpa::Doc::Bibliography/"Dominus 2005">.
Online, L<Wikipedia|Parse::Marpa::Doc::Bibliography/"Wikipedia"> is an excellent place to start.

=head3 Basic terms

A B<grammar> is a set of rules.
The B<rules> describe a set of strings of B<symbols>.
A string of symbols is often called a B<symbol string>.
The rules of a grammar are often called B<productions>.

=head3 Stages of Parsing

A B<recognizer> is a program that determines whether its B<input>
is one of the symbol strings in the set described by the rules of a grammar.
A B<parser> is a program which finds the structure of the input
according to the rules of a grammar.

The term B<parsing> is used in a strict and a loose sense.
B<Parsing> in the loose sense means the entire process of finding a grammar's structure,
including a separate recognition phase if the parser has one.  (Marpa does.)
If a parser has phases,
B<parsing in the strict sense> refers specifically to the phase that finds the structure of the input.
When this document intends the term B<parsing> in its strict sense, it will
speak explicitly of "parsing in the strict sense".
Otherwise, the term B<parsing> will mean parsing in the loose sense.

Parsers often use a
B<lexical analyzer> to convert B<raw input>,
usually B<input text>,
into a series of B<tokens>.
Each token represents a B<symbol> of the grammar and has a B<value>.
The series of symbols represented by the series of tokens
becomes the B<symbol string input>
seen by the recognizer.
The B<symbol string input> is also called the B<input sentence>.
A lexical analyzer is often called a B<lexer> or a B<scanner>,
and B<lexical analysis> is often called B<lexing> or B<scanning>.

=head3 Productions

A standard way of describing rules is Backus-Naur Form, or B<BNF>.
In one common way of writing BNF, a production looks like this.

    Expression ::= Term Factor

The equivalent in Marpa's MDL language looks like this:

    Expression: Term, Factor.

In the production above, C<Expression>, C<Term> and C<Factor> are symbols.
A production consists of a B<left hand side> and a B<right hand side>.
In a B<context-free grammar>,
like those Marpa parses,
the left hand side of a production 
is always a symbol string of length 1.
The right hand side of a production is a symbol string of zero or more symbols.
In the example, C<Expression> is the left hand side, and 
C<Term> and C<Factor> are right hand side symbols.

Left hand side and right hand side are often abbreviated as B<rhs> and B<lhs>.
If the rhs of a production has no symbols,
the production is called an B<empty production>
or an B<empty rule>.

Any symbol which is allowed to occur
in the symbol string input is called a B<terminal> symbol.
If the symbols in a symbol string are all terminals,
that symbol string is also called a B<sentence>.

=head3 Derivations

A B<step> of a derivation, or B<derivation step>, is made by taking a symbol string
and any production in the grammar whose lhs occurs in that first symbol string,
and replacing an occurrence of the lhs symbol in the first symbol string with the
rhs of the production.  For example, if C<A>, C<B>, C<C>, C<D>, and C<X> are symbols,
and

    X: B, C.

is a production, then

    A X D -> A B C D

is a derivation step, with "C<A X D>" as its beginning and "C<A B C D>" as its end or result.
We say that the string "C<A X D>"
B<derives> the string
"C<A B C D>".

A B<derivation> is a sequence of derivation steps.
The B<length> of a derivation is its length in steps.  A symbol string B<directly
derives> another if and only if there is a derivation of length 1 from the first symbol
string to the second string.  A symbol string is said to derive itself in a derivation
of length 0.  Such a zero length derivation is a B<trivial derivation>.

If a derivation is not trivial or direct, that is, if it has more than one step,
then it is an B<indirect> derivation.  A derviation which is not trivial, that is,
one which has one or more steps, is a B<non-trivial> derivation.

Where the symbol string beginning a derivation consists of a single symbol,
we often say that symbol B<produces> the symbol string which results from the derivation.
We say that the beginning symbol trivially, non-trivially, directly or indirectly produces
the symbol string if the length of the derivation is 0, greater than 0, 1, or greater than 1,
just as we do when we say a symbol string derives another symbol string.

When we say that a symbol produces or derives a symbol string,
we are taking a top-down point of view.
We sometimes take a bottom-up point of view,
and say that the symbol B<matches> the symbol string,
or that the symbol string B<matches> the symbol.

In any parse, one symbol is distinguished as the B<start symbol>.
The parse of an input is successful
if and only if the start symbol produces the input sentence
according to the grammar.

=head3 Nulling

The B<length> of a symbol string is the number of symbols in it.
The zero length symbol string is called the B<empty string>.
The empty string can be considered to be a sentence, in which
case it is the B<empty sentence>.
A string of one or more symbols is B<non-empty>.
A derivation which produces the empty string is a B<null derivation>.
A derivation from the start symbol which produces the empty string
is a B<null parse>.

If in a particular grammar, a symbol has a null derivation,
it is a B<nullable symbol>.
If, in a particular grammar,
the only sentence produced by a symbol is the empty sentence,
it is a B<nulling symbol>.
All nulling symbols are nullable symbols.

If a symbol is not nullable, it is B<non-nullable>.
If a symbol is not nulling, it is B<non-nulling>.
In any instance where a symbol produces the empty string,
it is said to be B<nulled>,
or to be a B<null symbol>.

=head3 Other Special Cases

If any derivation from the start symbol uses a rule,
that rule is called B<reachable> or B<accessible>.
A rule that is not accessible
is called B<unreachable> or B<inaccessible>.
If any derivation which results in a sentence uses a rule,
that rule is said to be B<productive>.
A rule that is not productive is called B<unproductive>.
A simple case of an unproductive rule is one whose rhs contains a symbol which is not
a terminal and not on the lhs of any other rule.
A B<useless> rule is one which is inaccessible or unproductive.

A symbol is B<reachable> if it appears in a reachable production.
A symbol is B<productive> if it appears on the lhs of a productive rule,
or if it is a nullable symbol.
If a symbol is not reachable or not accessible,
it is B<unreachable> or B<inaccessible>.
If a symbol is not productive,
it is B<unproductive>.

If any symbol in the grammar non-trivially produces a symbol string containing itself,
the grammar is said to be B<recursive>.
If any symbol non-trivially produces a symbol string with itself on the left,
the grammar is said to be B<left-recursive>.
If any symbol non-trivially produces a symbol string with itself on the right,
the grammar is said to be B<right-recursive>.
A non-trivial derivation of a symbol string from itself is a B<cycle>.

A grammar which contains no cycles is B<cycle-free>.
A B<proper context-free grammar> in one which is
cycle-free and has no useless rules or empty productions.

=head3 Structure

The structure of a parse can be represented by as a series of derivation steps from
the start symbol to the input.
If, for a particular grammar, more than one derivation is possible for an input,
that input is said to have an B<ambiguous> parse.
An B<ambiguous> grammar is one which for which there is some input
that has an ambiguous parse.

Another way to represent structure is as a B<parse tree>.
Every symbol used in the parse is
represented by a B<node> of the parse tree.
Wherever a production is used in the parse,
its lhs is represented by a B<parent node>
and the rhs symbols are represented by B<child nodes>.
The start symbol is the B<root> of the tree.
Terminals and symbols on the
left hand side of empty productions are B<leaf nodes>.
If a node is not a B<leaf node>, it is an B<inner node>.
A B<nulled node> is one that represents a nulled symbol.

The node at the root of the tree is the B<start node>.
Any node with a symbol being used as a terminal is a B<terminal node>.
A node closer to the root node is said to be B<higher>
than a node further away.

=head3 Semantics

In real life, the structure of a parse is usually a means to an end.
Grammars usually have a B<semantics> associated with them,
and what the user actually wants is the B<value> of the parse
according to the semantics.
The tree representation is especially useful when evaluating a parse.

Nulled nodes are treated specially in Marpa, as described
L<below|"Null Symbol Values">.
Nodes which are not nulled are evaluated in standard ways.
Every non-null leaf node which represents a terminal symbol
has a value associated with it on input.
Non-null inner nodes 
take their semantics from the production whose lhs they represent.
The semantics for a production
describe how to calculate the value of the node which represents the lhs
(the parent node)
from the values of zero or more of the nodes which represent the rhs symbols
(child nodes).
Values are computed recursively, bottom-up.
The value of a parse is the value of its start symbol.

=head2 The Easy Way

Most of Marpa's capabilities are available using a single static method:
L<C<Parse::Marpa::mdl>|/mdl>.
The C<mdl> method requires a grammar description in MDL (the Marpa Description Language) and a string.
C<mdl> parses the string according to the MDL description.
In scalar context, C<mdl> returns a reference to the value of the first parse.
In list context, it returns references to the values of all parses.
See L<below|/"mdl"> for more detail about the C<mdl> static method.

=head2 Semantic Actions

Marpa's semantics
are specified with Perl 5 code strings, called B<actions>.
Marpa allows lexing actions, a preamble action, rule actions and null symbol actions.

Actions are calculated in
a special namespace set aside for that purpose.
The preamble action is always run first
and can be used to initialize that namespace.

The result of an action is the result from running its Perl 5 code string.
From L<the synopsis|"SYNOPSIS">, here's a rule for an expression that does addition:

    Expression: Expression, /[+]/, Expression.

and here's its action:

    $_->[0] + $_->[2]

In rule actions, C<$_> is defined as a reference to an array of the values of the symbols
on the left hand side of the rule.

Marpa is targeted to Perl 6.
When Perl 6 is ready, Perl 6 code will become its default semantics.

=head2 Null Symbol Values

Every symbol has a B<null symbol value>,
or more briefly, a B<null value>,
and this is used as the value of the symbol when it is nulled.
The default null value is a Marpa option (C<default_null_value>).
If not explicitly set, C<default_null_value> is a Perl 5 undefined.

Every symbol can have its own null symbol value.
In cases where a null symbol derives other null symbols,
only the value of the symbol highest in the null derivation is used.
For more details, and examples, see L<Parse::Marpa::Evaluator/"Null Symbol Values">.

=head2 Lexing

The easiest way to parse a Perl 5 string in Marpa is to use
MDL's default lexing.
MDL allows terminals to be defined either as Perl 5 regexes or,
for difficult cases, as lex actions,
which are Perl 5 code.
Unlike most parser generators,
Marpa does not require that
the regexes and lex actions result in a deterministic lexer.
It is OK with Marpa if more than one token is possible at a location,
or if possible tokens overlap.
Ambiguities encountered in lexing are passed up to Marpa's parse engine,
and dealt with there.

Marpa allows terminals to appear on the left hand side of rules.
Most parsers have a problem with this, but Marpa does not.

Marpa is not restricted to MDL's model of lexing.
Advanced users can invent new models of the input, customized to their applications.
For more detail see L<Parse::Marpa::Grammar/"Tokens and Earlemes">.

=head2 Lack of Backward Compatibility

While this module is in alpha,
versions may not be backward compatible.
MDL protects users by requiring the version to be specified,
and by insisting on an exact match with Marpa's version number.
This strict version regime is the same as that being considered for Perl 6.
Nonetheless, Marpa's version matching may become less strict once it goes beta.

=head2 How to Read These Documents

The rest of L<this Description section|/Description> deals with advanced topics.
To create your first Marpa parser,
once you've finished with this document,
you want to read the
L<Parse::Marpa::Doc::MDL> document.
That has the details on how to create an MDL grammar description.
That should be all you need to get started.

In writing a grammar you don't always get it right the first time.
L<Parse::Marpa::Doc::Diagnostics>
describes techniques, named arguments and methods available for debugging
and tracing.

If you want to get into advanced uses of Marpa,
the
L<Parse::Marpa::Grammar>,
L<Parse::Marpa::Recognizer>,
and L<Parse::Marpa::Evaluator> documents
describe methods which allow you control over the individual phases
of the parse,
and discuss advanced topics associated with each phase.
L<Parse::Marpa::Doc::Plumbing> documents Marpa's plumbing.
L<Parse::Marpa::MDL> documents utilities for converting MDL symbol
names to plumbing interface names.
L<Parse::Marpa::Lex> documents some lex actions which are used
by MDL, and which are available to users for their own lexing.

For advanced diagnostics
or for reading Marpa's code,
it is necessary to understand Marpa's internals.
These are described in 
L<Parse::Marpa::Doc::Internals>.
Details about sources (books, web pages and articles) referred to in these documents
or used in the writing of Marpa
are collected in
L<Parse::Marpa::Doc::Bibliography>.
For those interested in theory,
L<Parse::Marpa::Doc::Algorithm> describes Marpa's algorithm,
explains how Marpa would not have been possible without the
the work of others,
and details what is new with Marpa.
L<Parse::Marpa::Doc::To_Do> is Marpa's list of things to do.

=head2 Phases

The C<mdl> method
hides the details of creating Marpa objects
and using Marpa's object methods from the user.
But for advanced applications,
and for tracing and diagnostics,
it is useful to know in detail how Marpa works.

Marpa parsing take place in three phases:
B<grammar creation>,
B<input recognition>
and B<parse evaluation>.
For brevity, I'll often speak of the the parse evaluation phase as
the B<evaluation> phase,
and the input recognition phase as
the B<recognition> phase.

Corresponding to the three phases,
Marpa has three kinds of object: grammars, recognizers and evaluators.
Recognizers are created from grammars and
evaluators are created from recognizers.

=head3 Grammars

Grammar objects (C<Parse::Marpa::Grammar>) are created first.
They may be created with rules or empty.
Rules may be added to them after they have been created.
After all the rules have been added, but before it is used to create a recognizer,
a grammar must be precomputed.
Details on grammar objects and methods can be found at L<Parse::Marpa::Grammar>.

=head3 Recognizers

To create a Marpa recognizer object (C<Parse::Marpa::Recognizer>),
a Marpa grammar object is required.
Once a recognizer object has been created, it can accept input.
You can create multiple recognizers from a single grammar,
and can safely run them simultaneously.

Recognizing an input is answering the "yes" or "no" question:
Does the input match the grammar?
While recognizing its input, Marpa builds tables.
Marpa's evaluation phase works from these tables.
Before creation of an evaluation object, 
the input has not been parsed in the strict sense of the term,
that is, its structure according to the grammar has not been determined.
For more details on recognizer objects and methods,
see L<Parse::Marpa::Recognizer>.

Currently, Marpa fully supports only non-streaming or "offline" input.
Marpa will also parse streamed inputs,
but the methods to find completed parses in a streamed input 
are still experimental.

=head3 Evaluators

In offline mode, once input is completed,
an evaluator object (C<Parse::Marpa::Evaluator>) can be created.
For each recognizer, only one evaluator object can
be in use at any one time.

An evaluator object is an iterator.
If the grammar is ambiguous,
the evaluator object can be used to return the values of all the parses.
For details on evaluator objects and methods,
see L<Parse::Marpa::Evaluator>.

=head2 Plumbing and Porcelain

A grammar is specified to Marpa through a B<grammar interface>.
There are two kinds of grammar interfaces,
B<porcelain> and B<plumbing>.
There is only one B<plumbing interface>.
As of the moment there is also only one
B<porcelain interface>,
the B<Marpa Demonstration Language>.

The B<plumbing> is a set of named arguments to
the C<new> and C<set> methods of
Marpa grammar objects.
Porcelain interfaces use the plumbing indirectly.
The plumbing is efficient,
but MDL is easier to read, write and maintain.
Users seeking efficiency are usually better off
using compiled MDL.
The documentation for the plumbing
is L<Parse::Marpa::Doc::Plumbing>.

There can be other porcelain interfaces.
Users are encouraged to design their own porcelain.
In Marpa's eyes all porcelain will be equal.
I call the porcelain that I am delivering with 
Marpa the Marpa Demonstration Language instead
of the "Marpa Language" to emphasize its lack of special status.
The documentation for MDL can be found at L<Parse::Marpa::Doc::MDL>.

=head2 Namespaces

Actions run in
special namespaces unique to each recognizer object.
These special namespaces belong entirely to the user.

In the following namespaces,
users should use only documented methods:

    Parse::Marpa
    Parse::Marpa::Grammar
    Parse::Marpa::Lex
    Parse::Marpa::MDL
    Parse::Marpa::Recognizer
    Parse::Marpa::Evaluator
    Parse::Marpa::Read_Only

Marpa namespaces and variables not mentioned in this section,
should not be relied on or modified.
Users should use variables in the
the C<Parse::Marpa::Read_Only> namespace on a read-only basis.

The C<$_> variable is made available to the rule actions,
and the C<$STRING> and C<$START> variables to the lex actions,
on a read-only basis,
except as described in the documentation.
Staying read-only can be tricky when dealing with Perl 5 arrays and hashes.
Be careful about auto-vivification!

=head2 Returns and Exceptions

Most Marpa methods return only if successful.
On failure they throw an exception using C<croak()>.
If you don't want the exception to be fatal, catch it using C<eval>.
A few failures are considered "non-exceptional" and returned.
Non-exceptional failures are described in the documentation for the method which returns them.

=head1 METHODS

=head2 mdl

     $first_result = Parse::Marpa::mdl(\$grammar_description, \$string_to_parse);

Z<>

     @all_results = Parse::Marpa::mdl(\$grammar_description, \$string_to_parse);

Z<>

     $first_result = Parse::Marpa::mdl(
         \$grammar_description,
         \$string_to_parse,
         { warnings => 0 }
     );

The C<mdl> static method takes three arguments:
a B<reference> to a string containing an MDL description of the grammar;
a B<reference> to a string with the text to be parsed;
and (optionally) a B<reference> to a hash with options.
The available options are described L<below|/"OPTIONS">.

In scalar context,  C<mdl> returns a B<reference> to the value of the first parse.
In list context, C<mdl> returns a list of B<references> to the values of the parses.
If there are no parses, C<mdl> returns undefined in scalar context and
the empty list in list context.

=head2 Diagnostic Methods

L<The separate document on diagnostics|Parse::Marpa::Doc::Diagnostics> deals
with methods for debugging grammars and parses.

=head1 OPTIONS

Marpa has options which control its behavior.
These may be set using named arguments when C<Parse::Marpa::Grammar>
and C<Parse::Marpa::Recognizer>
objects are created,
with the C<Parse::Marpa::Grammar::set> method, and
with the C<Parse::Marpa::mdl> static method.
Except as noted, recognizer objects inherit the Marpa option settings
of the grammar from which they were created,
and evaluator objects inherit the Marpa option settings
of the recognizer from which they were created.

The primary Marpa options are listed below, by argument name,
and described.
Options for debugging and tracing are described in
L<the separate document on diagnostics|Parse::Marpa::Doc::Diagnostics>.

Porcelain interfaces have their own conventions
for Marpa options.
The documentation of MDL describes,
and the documentation of all porcelain interfaces should describe,
which options can be set through that interface, and how.

=over 4

=item ambiguous_lex

Treats its value as a boolean. 
If true, ambiguous lexing is used.
Ambiguous lexing means that even if a terminal is matched
by a regex or a lex action,
the search for other terminals at that location continues.
If multiple terminals match,
all the tokens found are considered for use in the parse.
If the parse is ambiguous,
it is possible that all the tokens will actually be used.
Ambiguous lexing is the default.
The C<ambiguous_lex> option cannnot be changed after grammar precomputation.

If C<ambiguous_lex> is false,
Marpa does unambiguous lexing,
which is the standard in parser generators.
With unambiguous lexing,
lexing at each location ends when the first terminal matches.
The user must ensure the first terminal to match is the correct one.
Traditionally, users have done this by making their
lex patterns deterministic --
that is,
they set their lex patterns
up so that every valid input lexes in one and only one way.

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
The C<code_lines> option can be changed at any point in a parse.

=item default_action

Takes as its value a string, which must be code in the current
semantics.
(Right now Perl 5 is the only semantics available.)
This value is used as the action for rules which have no
explicitly specified action.
If C<default_action> is not set,
the default action is to return a Perl 5 undefined.
C<default_action> cannot be changed once a recognizer object has been created.

=item default_lex_prefix

The value must be a regex in the current semantics.
(Right now Perl 5 is the only semantics available.)
The lexers allow every terminal to specify a B<lex prefix>,
a pattern to be matched and discarded before the pattern for
the terminal itself is matched.
Lex prefixes are often used to handle leading whitespace.
C<default_lex_prefix> cannot be changed once a grammar is precomputed.

If a terminal has no lex prefix set, C<default_lex_prefix> is used.
When C<default_lex_prefix> is not set,
the default lex prefix is equivalent to a regex which matches
only the empty string.

=item default_null_value

The value must be an action, that is, a string containing code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The null value of a symbol is the symbol's value when it matches the empty string in a parse.
Null symbol values are calculated when a recognizer object is created.
C<default_null_value> cannot be changed after that point.

Symbols with an explicitly set null action
use the value returned by that explicitly set action.
Otherwise,
if there is a C<default_null_value> action, that 
action is run when the recognizer is created,
and the result becomes that symbol's null value.
If there is no C<default_null_value> action,
and a symbol has no explicitly set null action,
that symbol's null value is a Perl 5 undefined.
There's more about null values L<above|"Null Symbol Values"> and in
L<Parse::Marpa::Evaluator/"Null Symbol Values">.

=item max_parses

The value must be an integer.
If it is greater than zero, evaluators will return no more than that number
of parses.
If it is zero, there will be no limit on the number of parses returned
by an evaluator.
The default is for there to be no limit.
C<max_parses> can be changed at any point in the parse.

Grammars for which the number of parses grows exponentially with the length of the input
are common, and easy to create by mistake.
This option is one way to deal with that.

=item online

A boolean.
If true, Marpa runs in online or streaming mode.
If false, Marpa runs in offline mode.
The C<online> option cannot be changed after a recognizer is created.
Offline mode is the default, and the only mode supported
in this release.

In B<offline> mode,
when the first evaluator is created from a recognizer,
Marpa assumes that input to the recognizer has ended.
The recognizer does some final bookkeeping,
and refuses to accept any more input.

=item opaque

The C<opaque> option is used to set the opacity of an object.
Not specifying this option and accepting the default behavior is always safe.
A value of 1 marks the object opaque, which is the default, and which is also
always safe.

A value of 0 marks an object transparent.
If an evaluator object is marked transparent,
an optimization called "node value memoization" is enabled.
An evaluator should be marked transparent only if
its semantic actions can be safely memoized.

Recognizers inherit the opacity marking of the grammar used to create them,
if there was one.
If a recognizer is created from a grammar without an opacity marking,
and no C<opaque> option is specified,
the recognizer is marked opaque.
Evaluators inherit the opacity marking of the recognizer used to create them.
Once an object has been marked opaque,
its opacity setting cannot be changed.

Marpa marks a grammar opaque internally,
if the grammar uses certain kinds of sequence productions.
For more details,
see L<Parse::Marpa::Evaluator/"Node Memoization">.

=item preamble

The value must be a string which contains code in the current semantics.
(Right now Perl 5 is the only semantics available.)
The preamble is run
when the recognizer object is created,
in a namespace special to the recognizer object.
Rule actions and lex actions also run in this namespace.
A preamble may be used to set up globals.
The preamble of a recognizer object cannot be changed
after the recognizer object has been created.

If multiple preambles are specified as named arguments,
the most recent preamble replaces any earlier one.
This is consistent with the behavior of other named arguments,
but it differs from the behavior of MDL,
which creates a preamble by concatenating code strings.

=item semantics

The value is a string specifying the type of semantics used in the semantic actions.
The current default, and the only available semantics at this writing, is C<perl5>.
The C<semantics> option cannot be changed after the grammar is precomputed.

=item trace_file_handle

The value is a file handle.
Warnings and trace output go to the trace file handle.
By default it's C<STDERR>.
The trace file handle can be changed at any point in a parse.

=item version

If present, the C<version> option must match the current
Marpa version B<exactly>.
This is because while Marpa is in alpha,
features may change dramatically from version
to version.
The C<version> option cannot be changed after the grammar is precomputed.

=item warnings

The value is a boolean.
If true, it enables warnings
about inaccessible and unproductive rules in the grammar.
Warnings are written to the trace file handle.
By default, warnings are on.
Turning warnings on
after grammar precomputation is useless,
and itself results in a warning.

Inaccessible and unproductive rules sometimes indicate errors in the grammar
design.
But a user may have plans for them,
may wish to keep them as notes,
or may simply wish to deal with them later.

=back

=head1 IMPLEMENTATION NOTES

=head2 Exports and Object Orientation

Marpa exports nothing, either optionally or by default.
Use of object orientation in Marpa is superficial.
Only grammars, recognizers and evaluators are objects,
and they are not designed to be inherited.

=head2 Speed

Speed seems very good for an Earley's implementation.
In fact, current performance limits are more often a function of the lexing
than of the Marpa parse engine.

=head3 Ambiguous Lexing

Ambiguous lexing has a cost, and grammars which can turn ambiguous lexing off
can expect to parse twice as fast.
Right now when Marpa lexes with multiple regexes at a single location, it uses
a series of Perl 5 regex matches, one for each terminal.

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

The Marpa Demonstration Language was written
to demonstrate Marpa's capabilities,
including its lexing capabilities.
A porcelain interface which doesn't use ambiguous lexing could easily run
faster.
One with a customized lexer would be faster yet.

If MDL's parsing speed
becomes an issue for a particular grammar,
that grammar can be precompiled.
Subsequent runs of the precompiled grammar don't incur the overhead of either
MDL parsing or precomputation.
Marpa parses the user's MDL
using a grammar precompiled from an self-describing grammar written in MDL.

=head3 Comparison with other Parsers

In thinking about speed, it is helpful to
keep in mind Marpa's place in the parsing food chain.
Marpa parses grammars that B<bison>, B<yacc>, L<Parse::Yapp>,
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
Marpa never needs to backtrack.
It finds every possible parse the first time through.
Backtracking is a gamble,
and one you often find you've made against the odds.

Some grammars have constructs to control backtracking.
This control comes at a high price.
Solutions with these constructs built into them are
as unreadable as anything in the world of programming gets,
and fragile in the face of change to boot.

If you know you will be writing an LALR grammar or a regular one,
that is a good reason B<not> to use Marpa.
When a grammar is LALR or regular,
Marpa takes advantage of this and runs faster.
But such a grammar will run faster yet on a parser designed
for it:
B<bison>, B<yacc> and L<Parse::Yapp> for LALR; regexes
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
Marpa uses only Perl modules which are part of Marpa itself,
or are Perl core modules.

=head1 AUTHOR

Jeffrey Kegler

=head2 Why is it Called "Marpa"?

Marpa is the name of the greatest of the Tibetan "translators".
In his time (the 11th century AD) Indian Buddhism was
at its height.  A generation of scholars was devoting
itself to producing Tibetan versions of Buddhism's Sanskrit scriptures.
Marpa became the greatest of them,
and today he is known simply as Marpa Lotsawa: "Marpa the Translator".

Translation in the 11th century was not a job for the indoors type.
A translator needed to study with the teachers who had the
texts and could explain them.  That meant going to India.
Marpa lived in Tibet's
Lhotrak Valley.
To get to India, he needed to cross two hundred difficult and lawless miles to
the Khala Chela Pass,
then scale its three-mile high summit.

The last four hundred miles,
from Khala Chela to the great Buddhist center of Nalanda,
had turned out to be the most deadly.
The first expeditions had descended straight to the hot plains
and met disaster.
Almost no germs live in the cold,
thin air of Tibet.
With no immunity to India's diseases,
entire expeditions had been wiped out
within weeks of arrival.

=head2 Blatant Plug

There's more about Marpa in my new novel, B<The God Proof>, in which
his studies, travels and adventures are a major subplot.  B<The God
Proof> centers around Kurt GE<ouml>del's proof of God's existence.
Yes, I<that> Kurt GE<ouml>del, and yes, he really did work out a
God Proof (it's in his I<Collected Works>, Vol. 3, pp. 403-404).
B<The God Proof> is available
as a free download (L<http://www.lulu.com/content/933192>)
and in print form at Amazon.com:
L<http://www.amazon.com/God-Proof-Jeffrey-Kegler/dp/1434807355>.

=head1 BUGS

=head2 Non-intuitive Parse Order in Unusual Cases

This problem occurs when

=over 4

=item * an ambiguous production has more than two nullable symbols on the right hand side; and

=item * the order of the parses for that production matters.

=back

This doesn't happen in any practical grammars I've tried.
Perhaps it's a unnatural way to set up the semantics.
But it certainly does happen in textbook grammars.

A very straightforward workaround is described below.
But the problem needs to be fixed before Marpa goes beta.

Details: The problem occurs because these productions are rewritten internally by CHAF.
A rightmost parse comes first, as I have documented,
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

=head2 End of Line Comment Cannot be Last in MDL Source

A Perl style end of line comment cannot be last thing in MDL source.  Workaround:
Add a blank line.

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
was brief and long ago, but his openness to the idea was a major
encouragement,
and his insights into how humans do programming,
how they do languages,
and how those two endeavors interconnect,
a major influence.
More recently,
Allison Randal and Patrick Michaud have been generous with their
very valuable time.
They might have preferred that I volunteered as a Parrot cage-cleaner,
but if so, they were too polite to say.

Many at perlmonks.org answered questions for me.
I used answers from
chromatic, Corion, dragonchild,
jdporter, samtregar and Juerd,
among others,
in writing this module.
I'm just as grateful to those whose answers I didn't use.
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

Copyright 2007-2008 Jeffrey Kegler, all rights reserved.

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
