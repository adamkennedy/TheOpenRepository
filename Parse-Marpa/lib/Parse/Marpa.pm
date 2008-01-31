use 5.010_000;

package Parse::Marpa;

use warnings;
no warnings "recursion";
use strict;

# Maybe it'll be optional someday, but not now
use Parse::Marpa::MDL;

BEGIN {
    our $VERSION = '0.204000';
    our $STRING_VERSION = $VERSION;
    $VERSION = eval $VERSION;
}

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

our $compiled_eval_error;
BEGIN {
    eval "use Parse::Marpa::Source $Parse::Marpa::STRING_VERSION";
    $compiled_eval_error = $@;
    undef $Parse::Marpa::Internal::compiled_source_grammar
        if $compiled_eval_error;
}

=begin Implementation:

Structures and Objects: The design is to present an object-oriented
interface, but internally to avoid overheads.  So internally, where
objects might be used, I use array with constant indices to imitate
what in C would be structures.

=end Implementation:

=cut

# It's all integers, except for the version number
use integer;

package Parse::Marpa::Internal::Symbol;

use constant ID              => 0;
use constant NAME            => 1;
use constant LHS             => 2;     # rules with this as the lhs,
                                       # as a ref to an array of rule refs
use constant RHS             => 3;     # rules with this in the rhs,
                                       # as a ref to an array of rule refs
use constant ACCESSIBLE      => 4;     # reachable from start symbol?
use constant PRODUCTIVE      => 5;     # reachable from input symbol?
use constant START           => 6;     # is one of the start symbols?
use constant REGEX           => 7;     # regex, for terminals; undef otherwise
use constant NULLING         => 8;     # always is null?
use constant NULLABLE        => 9;     # can match null?
use constant NULL_VALUE      => 10;    # value when null
use constant NULL_ALIAS      => 11;    # for a non-nulling symbol,
                                       # ref of a its nulling alias,
                                       # if there is one
                                       # otherwise undef
use constant TERMINAL        => 12;    # terminal?
use constant CLOSURE         => 13;    # closure to do lexing
use constant PRIORITY        => 14;    # order, for lexing
use constant COUNTED         => 15;    # used on rhs of counted rule?
use constant ACTION          => 16;    # lexing action specified by user
use constant PREFIX          => 17;    # lexing prefix specified by user
use constant SUFFIX          => 18;    # lexing suffix specified by user
use constant IS_CHAF_NULLING => 19;    # if CHAF nulling lhs, ref to array
                                       # of rhs symbols

package Parse::Marpa::Internal::Rule;

use constant ID              => 0;
use constant NAME            => 1;
use constant LHS             => 2;     # ref of the left hand symbol
use constant RHS             => 3;     # array of symbol refs
use constant NULLABLE        => 4;     # can match null?
use constant ACCESSIBLE      => 5;     # reachable from start symbol?
use constant PRODUCTIVE      => 6;     # reachable from input symbol?
use constant NULLING         => 7;     # always matches null?
use constant USEFUL          => 8;     # use this rule in NFA?
use constant ACTION          => 9;     # action for this rule
use constant CLOSURE         => 10;    # closure for evaluating this rule
use constant ORIGINAL_RULE   => 11;    # for a rewritten rule, the original
use constant HAS_CHAF_LHS => 13;       # has CHAF internal symbol as lhs?
use constant HAS_CHAF_RHS => 14;       # has CHAF internal symbol on rhs?
use constant PRIORITY     => 15;       # rule priority

package Parse::Marpa::Internal::NFA;

use constant ID         => 0;
use constant NAME       => 1;
use constant ITEM       => 2;          # an LR(0) item
use constant TRANSITION => 3;          # the transitions, as a hash
                                       # from symbol name to NFA states

package Parse::Marpa::Internal::SDFA;

use constant ID             => 0;
use constant NAME           => 1;
use constant NFA_STATES     => 2;   # in an SDFA: an array of NFA states
use constant TRANSITION     => 3;   # the transitions, as a hash
                                    # from symbol name to SDFA states
use constant COMPLETE_LHS   => 4;   # an array of the lhs's of complete rules
use constant COMPLETE_RULES => 5;   # an array of lists of the complete rules,
                                    # indexed by lhs
use constant START_RULE     => 6;   # the start rule
use constant TAG            => 7;   # implementation-independant tag

package Parse::Marpa::Internal::LR0_item;

use constant RULE     => 0;
use constant POSITION => 1;

package Parse::Marpa::Internal::Grammar;

use constant ID              => 0;    # number of this grammar
use constant NAME            => 1;    # namespace special to this grammar
                                      # it should only be used BEFORE compilation, because it's not
                                      # guaranteed unique after decompilation
use constant RULES           => 2;    # array of rule refs
use constant SYMBOLS         => 3;    # array of symbol refs
use constant RULE_HASH       => 4;    # hash by name of rule refs
use constant SYMBOL_HASH     => 5;    # hash by name of symbol refs
use constant START           => 6;    # ref to start symbol
use constant NFA             => 7;    # array of states
use constant SDFA            => 8;    # array of states
use constant SDFA_BY_NAME    => 9;    # hash from SDFA name to SDFA reference
use constant NULLABLE_SYMBOL => 10;   # array of refs of the nullable symbols
use constant ACADEMIC        => 11;   # true if this is a textbook grammar,
                                      # for checking the NFA and SDFA, and NOT
                                      # for actual Earley parsing
use constant DEFAULT_NULL_VALUE => 12; # default value for nulling symbols
use constant DEFAULT_ACTION     => 13; # action for rules without one
use constant DEFAULT_LEX_PREFIX => 14; # default prefix for lexing
use constant DEFAULT_LEX_SUFFIX => 15; # default suffix for lexing
use constant AMBIGUOUS_LEX      => 16; # lex ambiguously?
use constant TRACE_RULES        => 17;
use constant TRACE_FILE_HANDLE  => 18;
use constant LOCATION_CALLBACK  => 19; # default callback for showing location
use constant VOLATILE           => 20; # default for volatility
use constant PROBLEMS           => 21; # fatal problems
use constant PREAMBLE           => 22; # default preamble
use constant STATE              => 23; # the grammar's state
use constant WARNINGS           => 24; # print warnings about grammar?
use constant VERSION            => 25; # Marpa version this grammar was compiled from
use constant CODE_LINES         => 26; # max lines to display on failure
use constant SEMANTICS          => 27; # semantics (currently perl5 only)
use constant TRACING            => 28; # master flag, set if any tracing is being done
                                       # (to control overhead for non-tracing processes)
use constant TRACE_STRINGS      => 29; # trace strings defined in marpa grammar
use constant TRACE_PREDEFINEDS  => 30; # trace predefineds in marpa grammar
use constant TRACE_PRIORITIES   => 31;
use constant TRACE_LEX_TRIES          => 32;
use constant TRACE_LEX_MATCHES        => 33;
use constant TRACE_ITERATION_SEARCHES => 34;
use constant TRACE_ITERATION_CHANGES  => 35;
use constant TRACE_EVALUATION_CHOICES => 36;
use constant TRACE_COMPLETIONS        => 37;
use constant TRACE_ACTIONS            => 38;
use constant TRACE_VALUES             => 39;
use constant MAX_PARSES               => 40;
use constant ONLINE                   => 41;
use constant ALLOW_RAW_SOURCE         => 42;

# values for state
use constant NEW          => "grammar without rules";
use constant SOURCE_RULES => "grammar with rules entered from source";
use constant PERL_RULES   => "grammar with rules entered from Perl";
use constant PRECOMPUTED  => "precomputed grammar";
use constant COMPILED     => "compiled grammar";
use constant EVALED       => "evaled grammar";
use constant IN_USE       => "in use grammar";

package Parse::Marpa::Read_Only;

# Public namespace reserved for dynamic globals, that is local() variables,
# available to the user on a read only basis.
# No actual globals should reside here

package Parse::Marpa::Internal::This;

# Internal namespace reserved for dynamic globals, that is local() variables.
# No actual globals should reside here

package Parse::Marpa::Internal;

use Parse::Marpa::Lex;

sub die_on_problems {
    my $fatal_error = shift;
    my $warnings = shift;
    my $where = shift;
    my $long_where = shift;
    my $code = shift;

    $long_where //= $where;
    my $grammar = $Parse::Marpa::Internal::This::grammar;
    my $code_lines = 30;
    $code_lines = $grammar->[ Parse::Marpa::Internal::Grammar::CODE_LINES ]
        if defined $grammar;
    my @msg;
    if (defined $code and defined $$code and $code_lines) {
        my $position = 0;
        if ($code_lines >= 0) {
            LINE: for (my $line = $code_lines; $line > 0; $line--) {
                $position = index($$code, "\n", $position);
                last LINE if $position < 0;
                $position++;
            }
        } else {
            $position = -1;
        }
        my $code_piece = $code;
        if ($position > 0) {
            $code_piece = \(
                substr($$code, 0, $position+1)
                . "[ Code truncated after $code_lines lines ]"
            )
        }
        push(@msg,
            "Problems in "
            . $long_where
            . ", code:\n"
            . $$code_piece
            . "\n"
        );
    }
    my $warnings_count = @$warnings;
    if ($warnings_count) {
        push(@msg, "Warnings ($warnings_count) in $where:\n", @$warnings);
        unless ($fatal_error) {
            $fatal_error = "Marpa will not continue due to warnings";
        }
    }
    push(@msg,
        "Fatal problem in $long_where\n",
        $fatal_error,
    );
    croak(@msg);
}

package Parse::Marpa::Internal::Source_Eval;

sub Parse::Marpa::Internal::raw_grammar_eval {
     my $grammar = shift;
     my $raw_grammar = shift;

     my ($trace_fh, $trace_strings, $trace_predefineds);
     if ($grammar-> [ Parse::Marpa::Internal::Grammar::TRACING  ]) {
         $trace_fh
             = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
         $trace_strings
             = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_STRINGS ];
         $trace_predefineds
             = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PREDEFINEDS ];
     }

     my $new_start_symbol;
     my $new_semantics;
     my $new_version;
     my $new_preamble;
     my $new_default_lex_prefix;
     my $new_default_action;
     my $new_default_null_value;
     my $new_rules;
     my $new_terminals;
     my %strings;

     {
         my @warnings;
         local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
         eval $$raw_grammar;
         my $fatal_error = $@;
         if ($fatal_error or @warnings) {
              Parse::Marpa::Internal::die_on_problems(
                  $fatal_error,
                  \@warnings,
                  "evaluating gramar",
                  "evaluating gramar",
                  $raw_grammar,
              );
         }
     }

     if ($trace_strings) {
         for my $string (keys %strings) {
             say $trace_fh qq{String "$string" set to '}, $strings{$string}, q{'};
         }
     }

     if (defined $new_start_symbol) {
         $grammar->[ Parse::Marpa::Internal::Grammar::START ] = $new_start_symbol;
         say $trace_fh "Start symbol set to ", $new_start_symbol
             if $trace_predefineds;
     }

     Carp::croak("Semantics must be set to perl5 in marpa grammar")
         if not defined $new_semantics or $new_semantics ne "perl5"; 
     $grammar->[ Parse::Marpa::Internal::Grammar::SEMANTICS ] = $new_semantics;
     say $trace_fh "Semantics set to ", $new_semantics
         if $trace_predefineds;

     Carp::croak("Version must be set in marpa grammar")
         if not defined $new_version;

     no integer;
     Carp::croak(
         "Version in marpa grammar ($new_version) does not match Marpa (",
         $Parse::Marpa::VERSION,
         ")"
     ) if $new_version != $Parse::Marpa::VERSION;
     use integer;

     $grammar->[ Parse::Marpa::Internal::Grammar::VERSION ] = $new_version;
     say $trace_fh "Version set to ", $new_version
          if $trace_predefineds;

     if (defined $new_preamble) {
         $grammar->[ Parse::Marpa::Internal::Grammar::PREAMBLE ] = $new_preamble;
         say $trace_fh "Preamble set to '", $new_preamble, q{'}
             if defined $trace_predefineds;
     }

     if (defined $new_default_lex_prefix) {
         $grammar->[ Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX ] = $new_default_lex_prefix;
         say $trace_fh "Default lex prefix set to '", $new_default_lex_prefix, q{'}
             if defined $trace_predefineds;
     }

     if (defined $new_default_action) {
         $grammar->[ Parse::Marpa::Internal::Grammar::DEFAULT_ACTION ] = $new_default_action;
         say $trace_fh "Default action set to '", $new_default_action, q{'}
             if $trace_predefineds;
     }

     if (defined $new_default_null_value) {
         $grammar->[ Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE ] = $new_default_null_value;
         say $trace_fh "Default null_value set to '", $new_default_null_value, q{'}
             if $trace_predefineds;
     }

     Parse::Marpa::Internal::add_user_rules($grammar, $new_rules);
     Parse::Marpa::Internal::add_user_terminals($grammar, $new_terminals);

     $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
         Parse::Marpa::Internal::Grammar::PERL_RULES;

}

package Parse::Marpa::Internal;

use Scalar::Util qw(weaken);
use Carp;
use Data::Dumper;
use Parse::Marpa::Lex;

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

    my $g = new Parse::Marpa(
        source => $grammar,
        %{$options}
    );
    my $parse = new Parse::Marpa::Recce(grammar => $g);

    my $failed_at_earleme = $parse->text($text);
    if ($failed_at_earleme >= 0) {
        die_with_parse_failure($text, $failed_at_earleme);
    }

    my $result = $parse->initial();
    return unless defined $result;
    my @values;
    push(@values, $parse->value());
    return $values[0] unless wantarray;
    push(@values, $parse->value()) while $parse->next;
    @values;
}

sub Parse::Marpa::new {
    my $class = shift;
    my %args  = @_;

    my $grammar = [];
    bless( $grammar, $class );
    local($Parse::Marpa::Internal::This::grammar) = $grammar;

    # set the defaults and the default defaults
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE]
        = *STDERR;
    state $grammar_number //= 0;
    $grammar->[Parse::Marpa::Internal::Grammar::ID] = $grammar_number++;

    # Note: this limits the number of grammar to the number of integers --
    # not likely to be a big problem.
    $grammar->[Parse::Marpa::Internal::Grammar::NAME] =
        sprintf( "Parse::Marpa::G_%x", $grammar_number );

    $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC]           = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] = "";
    $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX] = "";
    $grammar->[Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX]      = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::TRACE_RULES]        = 0;
    $grammar->[Parse::Marpa::Internal::Grammar::LOCATION_CALLBACK] =
        q{ "Earleme " . $earleme };
    $grammar->[Parse::Marpa::Internal::Grammar::VOLATILE] = undef;
    $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] = 30;
    $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
        Parse::Marpa::Internal::Grammar::NEW;
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS]      = [];
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH]  = {};
    $grammar->[Parse::Marpa::Internal::Grammar::RULES]        = [];
    $grammar->[Parse::Marpa::Internal::Grammar::RULE_HASH]    = {};
    $grammar->[Parse::Marpa::Internal::Grammar::SDFA_BY_NAME] = {};
    $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES ] = -1;
    $grammar->[Parse::Marpa::Internal::Grammar::ONLINE ] = 0;

    $grammar->set(%args);
}

our $compiled_source_grammar;

sub Parse::Marpa::show_source_grammar_status {
    my $status = $compiled_source_grammar ?  "Compiled" : "Raw";
    if ( $Parse::Marpa::Internal::compiled_eval_error ) {
        $status .= "\nCompiled source had error:\n" . $Parse::Marpa::Internal::compiled_eval_error;
    }
    $status;
}

# For use some day to make locator() more efficient on repeated calls
sub binary_search {
    my ($target, $data) = @_;  
    my ($lower, $upper) = (0, $#$data); 
    my $i;                       
    while ($lower <= $upper) {
	my $i = int(($lower + $upper)/2);
	given ($data->[$i]) {
	    when ($_ < $target) { $lower = $i; }
	    when ($_ > $target) { $upper = $i; }
	    default { return $i }
	} 
    }
    $lower
}

sub locator {
    my $earleme = shift;
    my $string = shift;

    my $lines;
    $lines //= [0];
    my $pos = pos $$string = 0;
    NL: while ($$string =~ /\n/g) {
	$pos = pos $$string;
        push(@$lines, $pos);
	last NL if $pos > $earleme;
    }
    my $line = (@$lines) - ($pos > $earleme ? 2 : 1);
    my $line_start = $lines->[$line];
    return ($line, $line_start);
}

sub Parse::Marpa::show_location {
    my $msg = shift;
    my $source = shift;
    my $earleme = shift;

    my ($line, $line_start) = locator($earleme, $source);
    my @msg = ($msg, " at line ", $line+1, ", earleme $earleme\n");
    given (index($$source, "\n", $line_start)) {
        when (undef) { push(@msg, substr($$source, $line_start), "\n") }
        default { push(@msg, substr($$source, $line_start, $_-$line_start), "\n") }
    }
    join("", @msg, (" " x ($earleme-$line_start)), "^\n");
}

sub die_with_parse_failure {
    my $source = shift;
    my $earleme = shift;

    croak(Parse::Marpa::show_location("Parse failed", $source, $earleme));
}

# The following method fails if "use Parse::Marpa::Raw_Source" is not
# specified by the user.  This is an undocumented bootstrapping routine,
# not having the "use" in this code saves a few cycles in the normal case.
# Also, forcing the user to be specific about the fact he's doing bootstrapping,
# seems like a good idea in itself.

sub Parse::Marpa::create_compiled_source_grammar {
    # Overwrite the existing compiled source grammar, if we already have one
    # This allows us to bootstrap in a new version

    my $raw_source_grammar = Parse::Marpa::Internal::raw_source_grammar();
    my $raw_source_version = $raw_source_grammar->[ Parse::Marpa::Internal::Grammar::VERSION ];
    if ( $raw_source_version != $Parse::Marpa::VERSION)
    {
        croak(
            "raw source grammar version ($raw_source_version) does not match Marpa version (",
            $Parse::Marpa::VERSION,
            ")"
        );
    }
    $raw_source_grammar->precompute();
    $raw_source_grammar->compile();
}

# First arg is the current grammar, that is, the one being
# built.
# Second arg is ref to string containing Marpa source
sub source_grammar {
    my $grammar = shift;
    my $source  = shift;
    my $source_options = shift;

    my $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
    my $allow_raw_source = $grammar->[ Parse::Marpa::Internal::Grammar::ALLOW_RAW_SOURCE ];
    if ( not defined $Parse::Marpa::Internal::compiled_source_grammar ) {
        if ( $allow_raw_source ) {
            $Parse::Marpa::Internal::compiled_source_grammar
                = Parse::Marpa::create_compiled_source_grammar();
        }
        else {
            my $eval_error = $Parse::Marpa::Internal::compiled_eval_error // "no eval error";
            croak("No compiled source grammar:\n", $eval_error);
        }
    }
    my $source_grammar = Parse::Marpa::decompile(
        $Parse::Marpa::Internal::compiled_source_grammar,
        $trace_fh
    );

    my $grammar_version = $source_grammar->[ Parse::Marpa::Internal::Grammar::VERSION ];
    no integer;
    if ($Parse::Marpa::VERSION != $grammar_version) {
        croak("Version mismatch between Marpa ($Parse::Marpa::VERSION) and its source grammar ($grammar_version)");
    }
    $source_options //= {};
    use integer;
    my $parse = new Parse::Marpa::Recce(
        grammar => $source_grammar,
        %{$source_options}
    );

    my $failed_at_earleme = $parse->text($source);
    if ($failed_at_earleme >= 0) {
        die_with_parse_failure($source, $failed_at_earleme);
    }
    my $result = $parse->initial();
    return unless defined $result;
    my $value = $parse->value();
    raw_grammar_eval($grammar, $value);
}

sub Parse::Marpa::set {
    my $grammar = shift;
    my %args    = @_;

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $precomputed = 1;
    my $state = $grammar->[Parse::Marpa::Internal::Grammar::STATE];
    given ($state) {
        when (Parse::Marpa::Internal::Grammar::NEW)          {$precomputed = 0}
        when (Parse::Marpa::Internal::Grammar::PERL_RULES)   {$precomputed = 0}
        when (Parse::Marpa::Internal::Grammar::SOURCE_RULES) {$precomputed = 0}
    }

    # value of source needs to be a *REF* to a string
    my $source = $args{"source"};
    if ( defined $source ) {
        croak("Cannot source grammar with some rules already defined")
            if $state ne Parse::Marpa::Internal::Grammar::NEW;
        croak("Source for grammar must be specified as string ref")
            unless ref $source eq "SCALAR";
        croak("Source for grammar undefined")
            if not defined $$source;
        source_grammar( $grammar, $source, $args{"source_options"} );
    }

    while ( my ( $option, $value ) = each %args ) {
        given ($option) {
            when ("source") {;}    # already dealt with
            when ("source_options") {;}    # already dealt with
            when ("rules") {
                croak("Perl rules not allowed with sourced grammar")
                    if $state eq
                        Parse::Marpa::Internal::Grammar::SOURCE_RULES;
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                add_user_rules( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
                    Parse::Marpa::Internal::Grammar::PERL_RULES;
            }
            when ("terminals") {
                croak("Perl terminals not allowed with sourced grammar")
                    if $state eq
                        Parse::Marpa::Internal::Grammar::SOURCE_RULES;
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                add_user_terminals( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
                    Parse::Marpa::Internal::Grammar::PERL_RULES;
            }
            when ("start") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[Parse::Marpa::Internal::Grammar::START] = $value;
                $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
                    Parse::Marpa::Internal::Grammar::PERL_RULES;
            }
            when ("academic") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] =
                    $value;
            }
            when ("default_null_value") {
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE] =
                    $value;
            }
            when ("default_action") {
                $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION] =
                    $value;
            }
            when ("default_lex_prefix") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] =
                    $value;
            }
            when ("default_lex_suffix") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX] =
                    $value;
            }
            when ("ambiguous_lex") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX] =
                    $value;
            }
            when ("trace_file_handle") {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE]
                    = $value;
            }
            when ("trace_actions") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ACTIONS ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
            }
            when ("trace_lex") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ]
                    = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ]
                    = $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
            }
            when ("trace_lex_tries") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
            }
            when ("trace_lex_matches") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
            }
            when ("trace_values") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_VALUES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
            }
            when ("trace_rules") {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_RULES] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_strings") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_STRINGS ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_predefineds") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PREDEFINEDS ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_evaluation_choices") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_EVALUATION_CHOICES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_iterations") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ]
                    = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ]
                    = $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_iteration_searches") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_iteration_changes") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_priorities") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("trace_completions") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS ] =
                    $value;
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
            }
            when ("location_callback") {
                croak("location callback not yet implemented");
            }
            when ("volatile") {
                given ($value) {
                    when (1) { $grammar->[Parse::Marpa::Internal::Grammar::VOLATILE] = 1; }
                    when (0) {
                        my $old_volatile = $grammar->[Parse::Marpa::Internal::Grammar::VOLATILE];
                        if (defined $old_volatile and $old_volatile) {
                            croak("volatile cannot be unset once it has be set");
                        }
                        $grammar->[Parse::Marpa::Internal::Grammar::VOLATILE] = 0;
                    }
                    default { croak("volatile must be set to either 0 or 1"); }
                } 
            }
            when ("warnings") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] =
                    $value;
            }
            when ("online") {
                $grammar->[Parse::Marpa::Internal::Grammar::ONLINE] =
                    $value;
            }
            when ("code_lines") {
                $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] =
                    $value;
            }
            when ("allow_raw_source") {
                $grammar->[Parse::Marpa::Internal::Grammar::ALLOW_RAW_SOURCE ] =
                    $value;
            }
            when ("max_parses") {
                $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES ] =
                    $value;
            }
            when ("version") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[ Parse::Marpa::Internal::Grammar::VERSION ] =
                    $value;
            }
            when ("semantics") {
                croak("$option option not allowed after grammar is precomputed")
                    if $precomputed;
                $grammar->[ Parse::Marpa::Internal::Grammar::SEMANTICS ] =
                    $value;
            }
            when ("preamble") {
                $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE] =
                    $value;
            }
            default {
                croak("$_ is not an available Marpa option");
            }
        }
    }

    $grammar;
}

=begin Implementation:

In order to automatically ELIMINATE inaccessible and unproductive
productions from a grammar, you have to first eliminate the
unproductive productions, THEN the inaccessible ones.  I don't do
this in the below.

The reason is my purposes are primarily diagnostic.  The difference
shows in the case of an unproductive start symbol.  Following the
correct procedure for automatically cleaning the grammar, I would
have to regard the start symbol and its productions as eliminated
and therefore go on to report every other production and symbol as
inaccessible.  Almost certainly all these inaccessiblity reports,
while theoretically correct, are irrelevant, since the user will
probably respond by making the start symbol productive, and the
extra "information" would only get in the way.

The downside is that in a few uncommon cases, a user relying entirely
on the Marpa warnings to clean up his grammar will have to go through
more than a single pass of the diagnostics.  I think even those
users will prefer simpler diagnostics, and I'm sure most users will.

=end Implementation:

=cut

sub Parse::Marpa::precompute {
    my $grammar = shift;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $state = $grammar->[ Parse::Marpa::Internal::Grammar::STATE ];
    given ($state) {
        when (Parse::Marpa::Internal::Grammar::PERL_RULES) { ; }
        when (Parse::Marpa::Internal::Grammar::SOURCE_RULES) { ; }
        when (Parse::Marpa::Internal::Grammar::PRECOMPUTED) {
            return $grammar; # if already done, just return
        }
        default {
            croak(
                "Attempt to precompute grammar in inappropriate state\nAttempt to precompute ",
                $state
            );
        }
    }

    nulling($grammar);
    nullable($grammar) or return $grammar;
    productive($grammar);

    my $start = $grammar->[Parse::Marpa::Internal::Grammar::START];
    croak("No start symbol specified") unless defined $start;

    set_start( $grammar, $start ) or return $grammar;

    accessible($grammar);
    detect_cycle($grammar);
    if ( $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] ) {
        setup_academic_grammar($grammar);
    }
    else {
        rewrite_as_CHAF($grammar);
    }
    create_NFA($grammar);
    create_SDFA($grammar);
    if ( $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] ) {
        my $trace_fh =
            $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
        for my $symbol ( @{ Parse::Marpa::inaccessible_symbols($grammar) } ) {
            say $trace_fh "Inaccessible symbol: $symbol";
        }
        for my $symbol ( @{ Parse::Marpa::unproductive_symbols($grammar) } ) {
            say $trace_fh "Unproductive symbol: $symbol";
        }
    }

    $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
        Parse::Marpa::Internal::Grammar::PRECOMPUTED;
    $grammar;
}

sub Parse::Marpa::show_problems {
    my $grammar = shift;

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        my $problem_count = scalar @$problems;
        return "Grammar has $problem_count problems:\n"
            . join("\n", @$problems)
            . "\n"
    }
    "Grammar has no problems\n";
}

# Deep Copy Grammar
#
# Note: copying strengthens weak refs
sub Parse::Marpa::compile {
    my $grammar = shift;

    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $state = $grammar->[ Parse::Marpa::Internal::Grammar::STATE ];
    given ($state) {
        when (Parse::Marpa::Internal::Grammar::PERL_RULES) { Parse::Marpa::precompute($grammar); }
        when (Parse::Marpa::Internal::Grammar::SOURCE_RULES) { Parse::Marpa::precompute($grammar); }
        when (Parse::Marpa::Internal::Grammar::PRECOMPUTED) { ; }
        default {
            croak(
                "Attempt to compile grammar in inappropriate state\nAttempt to compile ",
                $state
            );
        }
    }

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::show_problems($grammar),
            "Attempt to compile grammar with fatal problems\n",
            "Marpa cannot proceed"
        );
    }

    my $d = Data::Dumper->new( [$grammar], ["grammar"] );
    $d->Purity(1);
    $d->Indent(0);
    # returns a ref -- dumps can be long
    return \($d->Dump());
}

# First arg is compiled grammar
# Second arg (optional) is trace file handle, either saved and restored
# If not trace file handle supplied, it reverts to the default, STDERR
#
# Returns the decompiled grammar
sub Parse::Marpa::decompile {
    my $compiled_grammar = shift;
    my $trace_fh = shift;
    $trace_fh //= *STDERR;

    my $grammar;
    {
        my @warnings;
        local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
        eval $$compiled_grammar;
        my $fatal_error = $@;
        if ($fatal_error or @warnings) {
            die_on_problems(
                $fatal_error,
                \@warnings,
                "decompiling gramar",
                "decompiling gramar",
                $compiled_grammar,
            );
        }
    }

    $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ] = $trace_fh;

    # Eliminate or weaken all circular references
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    while ( my ( $name, $ref ) = each %{$symbol_hash} ) {
        weaken( $symbol_hash->{$name} = $ref );
    }

    # these were weak references, but aren't used anyway, so
    # free up the memory
    for my $symbol (
        @{ $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS] } )
    {
        $symbol->[Parse::Marpa::Internal::Symbol::LHS] = undef;
        $symbol->[Parse::Marpa::Internal::Symbol::RHS] = undef;
    }
    $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
        Parse::Marpa::Internal::Grammar::COMPILED;
    $grammar;

}

sub Parse::Marpa::show_symbol {
    my $symbol = shift;
    my $text   = "";
    $text .= sprintf "%d: %s, lhs=[%s], rhs=[%s]",
        $symbol->[Parse::Marpa::Internal::Symbol::ID],
        $symbol->[Parse::Marpa::Internal::Symbol::NAME],
        join( " ",
        map { $_->[Parse::Marpa::Internal::Rule::ID] }
            @{ $symbol->[Parse::Marpa::Internal::Symbol::LHS] } ),
        join( " ",
        map { $_->[Parse::Marpa::Internal::Rule::ID] }
            @{ $symbol->[Parse::Marpa::Internal::Symbol::RHS] } );
    if ( not $symbol->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] ) {
        $text .= " unproductive";
    }
    if ( not $symbol->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] ) {
        $text .= " inaccessible";
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
        $text .= " nullable";
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::NULLING] ) {
        $text .= " nulling";
    }
    if ( $symbol->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
        $text .= " terminal";
    }
    $text .= "\n";
}

sub Parse::Marpa::show_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    my $text    = "";
    for my $symbol_ref (@$symbols) {
        $text .= Parse::Marpa::show_symbol($symbol_ref);
    }
    $text;
}

sub Parse::Marpa::show_nulling_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::NULLING] }
            @$symbols );
}

sub Parse::Marpa::show_nullable_symbols {
    my $grammar = shift;
    my $symbols =
        $grammar->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @$symbols );
}

sub Parse::Marpa::show_productive_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] }
            @$symbols );
}

sub Parse::Marpa::show_accessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @$symbols );
}

sub Parse::Marpa::inaccessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    [   sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { !$_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @$symbols
    ];
}

sub Parse::Marpa::unproductive_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    [   sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { !$_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] }
            @$symbols
    ];
}

sub Parse::Marpa::brief_rule {
    my $rule = shift;
    my ( $lhs, $rhs, $rule_id ) = @{$rule}[
        Parse::Marpa::Internal::Rule::LHS,
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::ID
    ];
    my $text .= $rule_id . ": "
        . $lhs->[Parse::Marpa::Internal::Symbol::NAME] . " ->";
    if (@$rhs) {
        $text .= " "
            . join( " ",
            map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @$rhs );
    }
    $text;
}

sub Parse::Marpa::brief_original_rule {
    my $rule          = shift;
    my $original_rule = $rule->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE]
        // $rule;
    Parse::Marpa::brief_rule($original_rule);
}

sub Parse::Marpa::show_rule {
    my $rule = shift;

    my ( $rhs, $productive, $accessible, $nullable, $nulling,
        $useful, $priority, )
        = @{$rule}[
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::ACCESSIBLE,
        Parse::Marpa::Internal::Rule::NULLABLE,
        Parse::Marpa::Internal::Rule::NULLING,
        Parse::Marpa::Internal::Rule::USEFUL,
        Parse::Marpa::Internal::Rule::PRIORITY,
        ];
    my $text    = Parse::Marpa::brief_rule($rule);
    my @comment = ();

    if ( not(@$rhs) )           { push( @comment, "empty" ); }
    if ( not $productive ) { push( @comment, "unproductive" ); }
    if ( not $accessible ) { push( @comment, "inaccessible" ); }
    if ($nullable)              { push( @comment, "nullable" ); }
    if ($nulling)               { push( @comment, "nulling" ); }
    if ( not $useful )          { push( @comment, "!useful" ); }
    if ($priority)              { push( @comment, "priority=$priority" ); }
    if (@comment) {
        $text .= " " . join( " ", "/*", @comment, "*/" );
    }
    $text .= "\n";
}

sub Parse::Marpa::show_rules {
    my $grammar = shift;
    my $rules   = $grammar->[Parse::Marpa::Internal::Grammar::RULES];
    my $text;

    for my $rule (@$rules) {
        $text .= Parse::Marpa::show_rule($rule);
    }
    $text;
}

sub Parse::Marpa::show_item {
    my $item = shift;
    my $text = "";
    if ( not defined $item ) {
        $text .= "/* empty */";
    }
    else {
        my ( $rule, $position ) = @{$item}[
            Parse::Marpa::Internal::LR0_item::RULE,
            Parse::Marpa::Internal::LR0_item::POSITION
        ];
        my @names =
            ( $rule->[Parse::Marpa::Internal::Rule::LHS]
                ->[Parse::Marpa::Internal::Symbol::NAME] );
        push( @names,
            map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
                @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } );
        splice( @names, $position + 1, 0, "." );
        splice( @names, 1, 0, "::=" );
        $text .= join( " ", @names );
    }
    $text;
}

sub Parse::Marpa::show_NFA_state {
    my $state = shift;
    my ( $name, $item, $transition ) = @{$state}[
        Parse::Marpa::Internal::NFA::NAME,
        Parse::Marpa::Internal::NFA::ITEM,
        Parse::Marpa::Internal::NFA::TRANSITION
    ];
    my $text .= $name . ": " . Parse::Marpa::show_item($item) . "\n";
    for my $symbol_name ( sort keys %$transition ) {
        my $transition_states = $transition->{$symbol_name};
        $text
            .= " "
            . ( $symbol_name eq "" ? "empty" : "<" . $symbol_name . ">" )
            . " => "
            . join( " ",
            map { $_->[Parse::Marpa::Internal::NFA::NAME] }
                @$transition_states )
            . "\n";
    }
    $text;
}

sub Parse::Marpa::show_NFA {
    my $grammar = shift;
    my $text    = "";
    my $NFA     = $grammar->[Parse::Marpa::Internal::Grammar::NFA];
    for my $state (@$NFA) {
        $text .= Parse::Marpa::show_NFA_state($state);
    }
    $text;
}

sub Parse::Marpa::show_SDFA_state {
    my $state = shift;
    my $tags  = shift;

    my $text = "";
    my ( $id, $name, $NFA_states, $transition, $tag, $lexables, ) = @{$state}[
        Parse::Marpa::Internal::SDFA::ID,
        Parse::Marpa::Internal::SDFA::NAME,
        Parse::Marpa::Internal::SDFA::NFA_STATES,
        Parse::Marpa::Internal::SDFA::TRANSITION,
        Parse::Marpa::Internal::SDFA::TAG,
    ];

    $text .= defined $tags ? "St" . $tag : "S" . $id;
    $text .= ": " . $name . "\n";
    for my $NFA_state (@$NFA_states) {
        my $item = $NFA_state->[Parse::Marpa::Internal::NFA::ITEM];
        $text .= Parse::Marpa::show_item($item) . "\n";
    }

    for my $symbol_name ( sort keys %$transition ) {
        my ( $to_id, $to_name ) = @{ $transition->{$symbol_name} }[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::NAME
        ];
        $text
            .= " "
            . ( $symbol_name eq "" ? "empty" : "<" . $symbol_name . ">" )
            . " => "
            . ( defined $tags ? "St" . $tags->[$to_id] : "S" . $to_id ) . " ("
            . $to_name . ")\n";
    }
    $text;
}

sub tag_SDFA {
    my $grammar = shift;
    my $SDFA    = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    return if defined $SDFA->[0]->[Parse::Marpa::Internal::SDFA::TAG];
    my $tag = 0;
    for my $state (
        sort {
            $a->[Parse::Marpa::Internal::SDFA::NAME]
                cmp $b->[Parse::Marpa::Internal::SDFA::NAME]
        } @$SDFA
        )
    {
        $state->[Parse::Marpa::Internal::SDFA::TAG] = $tag++;
    }
}

sub Parse::Marpa::show_SDFA {
    my $grammar = shift;
    my $text    = "";
    my $SDFA    = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    for my $state (@$SDFA) { $text .= Parse::Marpa::show_SDFA_state($state); }
    $text;
}

sub Parse::Marpa::show_ii_SDFA {
    my $grammar = shift;
    my $text    = "";
    my $SDFA    = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    my $tags;
    tag_SDFA($grammar);

    for my $state (@$SDFA) {
        $tags->[ $state->[Parse::Marpa::Internal::SDFA::ID] ] =
            $state->[Parse::Marpa::Internal::SDFA::TAG];
    }
    for my $state (
        map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map  { [ $_, $_->[Parse::Marpa::Internal::SDFA::TAG] ] } @$SDFA
        )
    {
        $text .= Parse::Marpa::show_SDFA_state( $state, $tags );
    }
    $text;
}

sub Parse::Marpa::get_symbol {
    my $grammar = shift;
    my $name    = shift;
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    defined $symbol_hash ? $symbol_hash->{$name} : undef;
}

sub add_terminal {
    my $grammar  = shift;
    my $name     = shift;
    my $options    = shift;
    my ( $regex, $prefix, $suffix );
    my $action;
    my $priority = 0;

    while (my ($key, $value) = each %{$options}) {
        given ($key) {
           when ("priority") { $priority = $value; }
           when ("action") { $action = $value; }
           when ("prefix") { $prefix = $value; }
           when ("suffix") { $suffix = $value; }
           when ("regex") { $regex = $value; }
           default {
               croak("Attempt to add terminal named $name with unknown option $key");
           }
        }
    }

    my ( $symbol_hash, $symbols, $default_null_value ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    # I allow redefinition of a LHS symbol as a terminal
    # I need to test that this works, or disallow it
    my $symbol = $symbol_hash->{$name};
    if ( defined $symbol ) {

        if ( $symbol->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
            croak("Attempt to add terminal twice: $name");
        }

        @{$symbol}[
            Parse::Marpa::Internal::Symbol::PRODUCTIVE,
            Parse::Marpa::Internal::Symbol::NULLING,
            Parse::Marpa::Internal::Symbol::REGEX,
            Parse::Marpa::Internal::Symbol::PREFIX,
            Parse::Marpa::Internal::Symbol::SUFFIX,
            Parse::Marpa::Internal::Symbol::ACTION,
            Parse::Marpa::Internal::Symbol::TERMINAL,
            Parse::Marpa::Internal::Symbol::PRIORITY,
            ]
            = ( 1, 0, $regex, $prefix, $suffix, $action, 1, $priority, );

        return;
    }

    my $symbol_count = @$symbols;
    my $new_symbol   = [];
    @{$new_symbol}[
        Parse::Marpa::Internal::Symbol::ID,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::REGEX,
        Parse::Marpa::Internal::Symbol::ACTION,
        Parse::Marpa::Internal::Symbol::TERMINAL,
        Parse::Marpa::Internal::Symbol::PRIORITY,
        ]
        = (
        $symbol_count, $name, [], [], 0, 1, 0, $regex,
        $action, 1, $priority,
        );

    push( @$symbols, $new_symbol );
    weaken( $symbol_hash->{$name} = $new_symbol );
}

sub assign_symbol {
    my $grammar = shift;
    my $name    = shift;
    my ( $symbol_hash, $symbols, $default_null_value, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    my $symbol_count = @$symbols;
    my $symbol       = $symbol_hash->{$name};
    if ( not defined $symbol ) {
        @{$symbol}[
            Parse::Marpa::Internal::Symbol::ID,
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::LHS,
            Parse::Marpa::Internal::Symbol::RHS,
            ]
            = ( $symbol_count, $name, [], [] );
        push( @$symbols, $symbol );
        weaken( $symbol_hash->{$name} = $symbol );
    }
    $symbol;
}

sub assign_user_symbol {
    my $self = shift;
    my $name = shift;
    croak("Symbol name $name ends in ']': that's not allowed")
        if $name =~ /_$/;
    assign_symbol( $self, $name );
}

sub add_user_rule {
    my $grammar   = shift;
    my $lhs_name  = shift;
    my $rhs_names = shift;
    my $action    = shift;
    my $priority  = shift;

    my ($rule_hash) = @{$grammar}[Parse::Marpa::Internal::Grammar::RULE_HASH];

    my $lhs_symbol = assign_user_symbol( $grammar, $lhs_name );
    $rhs_names //= [];
    my $rhs_symbols =
        [ map { assign_user_symbol( $grammar, $_ ); }
            @$rhs_names ];

    # Don't allow the user to duplicate a rule
    my $rule_key = join( ",",
        map { $_->[Parse::Marpa::Internal::Symbol::ID] }
            ( $lhs_symbol, @$rhs_symbols ) );
    croak( "Duplicate rule: ", $lhs_name, " -> ", join( " ", @$rhs_names ) )
        if exists $rule_hash->{$rule_key};

    $rule_hash->{$rule_key} = 1;

    add_rule( $grammar, $lhs_symbol, $rhs_symbols, $action, $priority );
}

sub add_rule {
    my $grammar  = shift;
    my $lhs      = shift;
    my $rhs      = shift;
    my $action   = shift;
    my $priority = shift;

    my ( $rules, $package, $trace_rules, $trace_fh, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::NAME,
        Parse::Marpa::Internal::Grammar::TRACE_RULES,
        Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE,
    ];

    my $rule_count = @$rules;
    my $new_rule   = [];
    my $nulling    = @$rhs ? undef : 1;
    $priority //= 0;

    @{$new_rule}[
        Parse::Marpa::Internal::Rule::ID,
        Parse::Marpa::Internal::Rule::NAME,
        Parse::Marpa::Internal::Rule::LHS,
        Parse::Marpa::Internal::Rule::RHS,
        Parse::Marpa::Internal::Rule::NULLABLE,
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::NULLING,
        Parse::Marpa::Internal::Rule::ACTION,
        Parse::Marpa::Internal::Rule::PRIORITY,
    ] = (
        $rule_count, "rule $rule_count",
        $lhs,        $rhs,
        $nulling, $nulling, $nulling,
        $action,
        $priority,
    );

    push( @$rules, $new_rule );
    {
        my $lhs_rules = $lhs->[Parse::Marpa::Internal::Symbol::LHS];
        weaken( $lhs_rules->[ scalar @$lhs_rules ] = $new_rule );
    }
    if ($nulling) {
        @{$lhs}[
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::PRODUCTIVE
            ]
            = ( 1, 1 );
    }
    else {
        my $last_symbol = [];
        SYMBOL: for my $symbol ( sort @$rhs ) {
            next SYMBOL if $symbol == $last_symbol;
            my $rhs_rules = $symbol->[Parse::Marpa::Internal::Symbol::RHS];
            weaken( $rhs_rules->[ scalar @$rhs_rules ] = $new_rule );
            $last_symbol = $symbol;
        }
    }
    if ($trace_rules) {
        print $trace_fh "Added rule #", $#$rules, ": ",
            $lhs->[Parse::Marpa::Internal::Symbol::NAME], " -> ",
            join( " ",
            map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @$rhs ),
            "\n";
    }
    $new_rule;
}

# add one or more rules
sub add_user_rules {
    my $grammar = shift;
    my $rules   = shift;

    RULE: for my $rule (@$rules) {

        given ( ref $rule ) {
            when ("ARRAY") {
                my $arg_count = @$rule;

                # This warning can be removed if this interface remains
                # internal
                if ( $arg_count > 4 or $arg_count < 1 ) {
                    croak(
                        "Rule has $arg_count arguments: "
                            . join( ", ",
                            map { defined $_ ? $_ : "undef" } @$rule )
                            . "\n"
                            . "Rule must have from 1 to 3 arguments"
                    );
                }
                my ( $lhs, $rhs, $action, $priority ) = @$rule;
                add_user_rule( $grammar, $lhs, $rhs, $action, $priority );

            }
            when ("HASH") {
                add_rules_from_hash( $grammar, $rule );
            }
            default {
                croak( "Invalid rule reftype ", ( $_ ? $_ : "undefined" ) );
            }
        }

    }    # RULE

}

sub add_rules_from_hash {
    my $grammar = shift;
    my $options = shift;

    my ( $lhs_name, $rhs_names, $action );
    my ( $min,      $max,       $separator_name );
    my $proper_separation = 0;
    my $keep_separation   = 0;
    my $left_associative  = 1;
    my $priority          = 0;

    while ( my ( $option, $value ) = each(%$options) ) {
        given ($option) {
            when ("rhs")               { $rhs_names         = $value }
            when ("lhs")               { $lhs_name          = $value }
            when ("action")            { $action            = $value }
            when ("min")               { $min               = $value }
            when ("max")               { $max               = $value }
            when ("separator")         { $separator_name    = $value }
            when ("proper_separation") { $proper_separation = $value }
            when ("keep_separation")   { $keep_separation   = $value }
            when ("left_associative")  { $left_associative  = $value }
            when ("right_associative") { $left_associative  = !$value }
            when ("priority")          { $priority          = $value }
            default { croak("Unknown option in counted rule: $option") };
        }
    }

    # Take care of nulling rules
    if ( scalar @$rhs_names == 0 ) {
        add_user_rule( $grammar, $lhs_name, $rhs_names, $action, $priority );
        return;
    }

    # Take of obviously bad min, max values
    if ( defined $max and $max <= 0 ) {
        croak("rule max count is $max, not greater than zero");
    }
    if ( defined $min and $min < 0 ) {
        croak("rule min count is $min, less than zero");
    }

    # Ensure min is correctly defined
    if ( not defined $min ) {
        given ($max) {
            when (undef) { $min = $max = 1; }
            default {
                croak("rule max count is defined ($max), but no rule minium");
            }
        }
    }

    # This is an ordinary, non-counted rule,
    # which we'll take care of first as a special case
    if ( defined $max and $max == 1 and $min == 1 ) {
        if ( $max <= 1 and defined $separator_name ) {
            croak("separator defined for rule without repetitions");
        }
        add_user_rule( $grammar, $lhs_name, $rhs_names, $action, $priority );
        return;
    }

    if ( defined $max ) {
        croak("rule max count ($max) count is less than minium ($min)")
            if $max < $min;
        croak("Too many symbols on rhs for counted rule")
            if scalar @$rhs_names != 1;
        my $rhs_name = pop @$rhs_names;

        # specifically counted rules
        my $new_rule;
        for my $count ( $min .. $max ) {
            my $proper_counted_rhs;
            my $separator_terminated_rhs;
            my @separated_rhs = ($rhs_name);
            push( @separated_rhs, $separator_name )
                if defined $separator_name;
            given ($count) {
                when (0) { $proper_counted_rhs = [] }
                default {
                    $proper_counted_rhs =
                        [ (@separated_rhs) x ( $count - 1 ), $rhs_name ];
                    if ( not $proper_separation and defined $separator_name )
                    {
                        $separator_terminated_rhs =
                            [ (@separated_rhs) x ($count) ];
                    }
                }
            }

            # no change to @Parse::Marpa::Read_Only::v needed for action
            if ( defined $separator_name and not $keep_separation ) {
                $action = q{ $Parse::Marpa::Read_Only::v = [
                        @{$Parse::Marpa::Read_Only:v}[
                           grep { !($_ % 2) } (0 .. $#$Parse::Marpa::Read_Only::v)
                        ]
                    }
                    . $action;
            }
            $new_rule =
                add_user_rule( $grammar, $lhs_name, $proper_counted_rhs,
                $action, $priority );
            if ($separator_terminated_rhs) {
                add_user_rule( $grammar, $lhs_name, $separator_terminated_rhs,
                    $action, $priority );
            }
        }

        # There will be at least one rhs symbol since we take the last rule created
        # and max >= 1
        my $rhs = $new_rule->[Parse::Marpa::Internal::Rule::RHS]->[0];
        $rhs->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;
        if ( defined $separator_name ) {
            my $separator =
                $new_rule->[Parse::Marpa::Internal::Rule::RHS]->[1];
            $separator->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;
        }

        return;

    }    # min and max both defined

    # At this point we know that max is undefined, and that min must be

    # Right now we're doing this right associative.  Add option later to be
    # left associative?

    # nulling rule is special case
    if ( $min == 0 ) {
        my $rule_action;
        given ($action) {
            when (undef) { $rule_action = undef }
            default {
                $rule_action = q{ $Parse::Marpa::Read_Only::v = []; } . $action;
            }
        }
        add_user_rule( $grammar, $lhs_name, [], $rule_action, $priority );
        $min = 1;
    }

    croak("Only one rhs symbol allowed for counted rule")
        if scalar @$rhs_names != 1;

    # create the rhs symbol
    my $rhs_name           = pop @$rhs_names;
    my $rhs                = assign_user_symbol( $grammar, $rhs_name );
    $rhs->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;

    # create the separator symbol, if we're using one
    my $separator;
    if ( defined $separator_name ) {
        $separator = assign_user_symbol( $grammar, $separator_name );
        $separator->[Parse::Marpa::Internal::Symbol::COUNTED] = 1;
    }

    # create the sequence symbol
    my $sequence_name = $rhs_name . "[Seq:$min-*]";
    if (defined $separator_name) {
        my $punctuation_free_separator_name = $separator_name;
        $punctuation_free_separator_name =~ s/[^[:alnum:]]/_/g;
        $sequence_name .= "[Sep:" . $punctuation_free_separator_name . "]"
    }
    my $unique_name_piece = sprintf("[x%x]", scalar @{$grammar->[ Parse::Marpa::Internal::Grammar::SYMBOLS ]});
    $sequence_name .= $unique_name_piece;
    my $sequence = assign_symbol( $grammar, $sequence_name );

    my $lhs = assign_user_symbol( $grammar, $lhs_name );

    # Don't allow the user to duplicate a rule
    # I'm pretty general here -- I consider a sequence rule a duplicate if rhs, lhs
    # and separator are the same.  I may want to get more fancy, but save that
    # for later.
    {
        my $rule_hash =
            $grammar->[Parse::Marpa::Internal::Grammar::RULE_HASH];
        my @key_rhs =
            defined $separator ? ( $rhs, $separator, $rhs ) : ($rhs);
        my $rule_key = join( ",",
            map { $_->[Parse::Marpa::Internal::Symbol::ID] }
                ( $lhs, @key_rhs ) );
        croak( "Duplicate rule: ",
            $lhs_name, " -> ", join( ",", @$rhs_names ) )
            if exists $rule_hash->{$rule_key};
        $rule_hash->{$rule_key} = 1;
    }

    # The following rules make evaluations volatile
    $grammar->[Parse::Marpa::Internal::Grammar::VOLATILE] = 1;

    my $rule_action;
    given ($action) {
        when (undef) { $rule_action = undef; }
        default {
            if ($left_associative) {

                # more efficient way to do this?
                $rule_action = q{
                    HEAD: for (;;) {
                        my $head = shift @$Parse::Marpa::Read_Only::v;
                        last HEAD unless scalar @$head;
                        unshift(@$Parse::Marpa::Read_Only::v, @$head);
                    }
                }
            }
            else {
                $rule_action = q{
                    TAIL: for (;;) {
                        my $tail = pop @$Parse::Marpa::Read_Only::v;
                        last TAIL unless scalar @$tail;
                        push(@$Parse::Marpa::Read_Only::v, @$tail);
                    }
                }
            }
            $rule_action .= $action;
        }
    }
    add_rule( $grammar, $lhs, [$sequence], $rule_action, $priority, );
    if ( defined $separator and not $proper_separation ) {
        unless ($keep_separation) {
            $rule_action = q{ pop @$Parse::Marpa::Read_Only::v; } . ($rule_action // "") ;
        }
        add_rule( $grammar, $lhs, [ $sequence, $separator, ],
            $rule_action, $priority, );
    }

    my @separated_rhs = ($rhs);
    push( @separated_rhs, $separator ) if defined $separator;

    # minimal sequence rule
    my $counted_rhs = [ (@separated_rhs) x ( $min - 1 ), $rhs ];

    if ($left_associative) {
        if ( defined $separator and not $keep_separation ) {
            $rule_action = q{
                [
                    [],
                    @{$Parse::Marpa::Read_Only::v}[
                        grep { !($_ % 2) } (0 .. $#$Parse::Marpa::Read_Only::v)
                    ]
                ]
            }
        }
        else {
            $rule_action = q{
                unshift(@$Parse::Marpa::Read_Only::v, []);
                $Parse::Marpa::Read_Only::v 
            }
        }
    }
    else {
        if ( defined $separator and not $keep_separation ) {
            $rule_action = q{
                [
                    @{$Parse::Marpa::Read_Only::v}[
                        grep { !($_ % 2) } (0 .. $#$Parse::Marpa::Read_Only::v)
                    ],
                    []
                ]
            }
        }
        else {
            $rule_action = q{
                push(@$Parse::Marpa::Read_Only::v, []);
                $Parse::Marpa::Read_Only::v 
            }
        }
    }

    add_rule( $grammar, $sequence, $counted_rhs, $rule_action, $priority, );

    # iterating sequence rule
    $rule_action = ( defined $separator and not $keep_separation )
        ? q{
            [
                @{$Parse::Marpa::Read_Only::v}[
                   grep { !($_ % 2) } (0 .. $#$Parse::Marpa::Read_Only::v)
                ],
            ]
        }
        : q{
            $Parse::Marpa::Read_Only::v
        };
    my @iterating_rhs = ( @separated_rhs, $sequence );
    if ($left_associative) {
        @iterating_rhs = reverse @iterating_rhs;
    }
    add_rule( $grammar, $sequence, ( \@iterating_rhs ),
        $rule_action, $priority, );

}    # sub add_rules_from_hash

sub add_user_terminals {
    my $grammar   = shift;
    my $terminals = shift;

    TERMINAL: for my $terminal (@$terminals) {
        my $arg_count = @$terminal;
        if ( $arg_count > 2 or $arg_count < 1 ) {
            croak("terminal must have from 1 or 2 arguments");
        }
        my ( $lhs_name, $options ) = @$terminal;
        add_user_terminal( $grammar, $lhs_name, $options );
    }
}

sub add_user_terminal {
    my $grammar  = shift;
    my $name = shift;
    my $options    = shift;

    croak("Symbol name $name ends in ']': that's not allowed")
        if $name =~ /_$/;
    add_terminal( $grammar, $name, $options );
}

sub set_start {
    my $grammar    = shift;
    my $start_name = shift;
    my $success = 1;

    # my $trace_fh =
        # $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
    my $symbol_hash =
        $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH];
    my $start = $symbol_hash->{$start_name};

    if ( not defined $start ) {
        my $problem = "Start symbol: " . $start_name . " not defined";
        push(
            @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem
        );
        $success = 0;
    }

    my ( $lhs, $rhs, $terminal, $productive ) = @{$start}[
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::TERMINAL,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
    ];

    if ( not scalar @$lhs and not $terminal ) {
        my $problem = "Start symbol " . $start_name . " not on LHS of any rule";
        push(
            @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem
        );
        $success = 0;
    }

    if ( not $productive ) {
        my $problem = "Unproductive start symbol: " . $start_name;
        push(
            @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem
        );
        $success = 0;
    }

    $grammar->[Parse::Marpa::Internal::Grammar::START] = $start;

    $success;
}

# return list of rules reachable from the start symbol;
sub accessible {
    my $grammar = shift;
    my $start   = $grammar->[Parse::Marpa::Internal::Grammar::START];

    $start->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] = 1;
    my $symbol_work_set = [$start];
    my $rule_work_set   = [];

    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS: while ( my $work_symbol = shift @$symbol_work_set ) {
            my $rules_produced =
                $work_symbol->[Parse::Marpa::Internal::Symbol::LHS];
            PRODUCED_RULE: for my $rule (@$rules_produced) {

                next PRODUCED_RULE
                    if defined $rule
                        ->[Parse::Marpa::Internal::Rule::ACCESSIBLE];

                $rule->[Parse::Marpa::Internal::Rule::ACCESSIBLE] = 1;
                $work_to_do++;
                push( @$rule_work_set, $rule );

            }
        }    # SYMBOL_PASS

        RULE: while ( my $work_rule = shift @$rule_work_set ) {
            my $rhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::RHS];

            RHS: for my $symbol (@$rhs_symbol) {

                next RHS
                    if defined $symbol
                        ->[Parse::Marpa::Internal::Symbol::ACCESSIBLE];
                $symbol->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] =
                    1;
                $work_to_do++;

                push( @$symbol_work_set, $symbol );
            }

        }    # RULE

    }    # work_to_do loop

}

sub productive {
    my $grammar = shift;

    my ( $rules, $symbols ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS
    ];

    # If a symbol's nullability could not be determined, it was unproductive.
    # All nullable symbols are productive.
    for my $symbol (@$symbols) {
        if ( not defined $_->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 0;
        }
        if ( $_->[Parse::Marpa::Internal::Symbol::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 1;
        }
    }

    # If a rule's nullability could not be determined, it was unproductive.
    # All nullable rules are productive.
    for my $rule (@$rules) {
        if ( not defined $rule->[Parse::Marpa::Internal::Rule::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 0;
        }
        if ( $rule->[Parse::Marpa::Internal::Rule::NULLABLE] ) {
            $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] = 1;
        }
    }

    my $symbol_work_set = [];
    $#$symbol_work_set = $#$symbols;
    my $rule_work_set = [];
    $#$rule_work_set = $#$rules;

    for my $symbol_id (
        grep {
            defined $symbols->[$_]
                ->[Parse::Marpa::Internal::Symbol::PRODUCTIVE]
        } ( 0 .. $#$symbols )
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }
    for my $rule_id (
        grep {
            defined $rules->[$_]
                ->[Parse::Marpa::Internal::Rule::PRODUCTIVE]
        } ( 0 .. $#$rules )
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }
    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#$symbol_work_set ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;

            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];
            PRODUCING_RULE: for my $rule (@$rules_producing) {

                # no work to do -- this rule already has productive status marked
                next PRODUCING_RULE
                    if defined $rule
                        ->[Parse::Marpa::Internal::Rule::PRODUCTIVE];

                # assume productive until we hit an unmarked or unproductive symbol
                my $rule_productive = 1;

                # are all symbols on the RHS of this rule bottom marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $productive = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::PRODUCTIVE];

                    # unmarked symbol, change the assumption for rule to undef,
                    # but keep scanning for unproductive
                    # symbol, which will override everything else
                    if ( not defined $productive ) {
                        $rule_productive = undef;
                        next RHS_SYMBOL;
                    }

                    # any unproductive RHS symbol means the rule is unproductive
                    if ( $productive == 0 ) {
                        $rule_productive = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule productive or unproductive, mark the rule
                if ( defined $rule_productive ) {
                    $rule->[Parse::Marpa::Internal::Rule::PRODUCTIVE] =
                        $rule_productive;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#$rule_work_set ) )
        {
            my $work_rule = $rules->[$rule_id];
            $rule_work_set->[$rule_id] = 0;
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already has productive status marked
            next RULE
                if defined $lhs_symbol
                    ->[Parse::Marpa::Internal::Symbol::PRODUCTIVE];

            # assume unproductive until we hit an unmarked or non-nullable symbol
            my $symbol_productive = 0;

            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $productive =
                    $rule->[Parse::Marpa::Internal::Rule::PRODUCTIVE];

                # unmarked symbol, change the assumption for rule to undef, but keep scanning for nullable
                # rule, which will override everything else
                if ( not defined $productive ) {
                    $symbol_productive = undef;
                    next LHS_RULE;
                }

                # any productive rule means the LHS is productive
                if ( $productive == 1 ) {
                    $symbol_productive = 1;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol productive or unproductive, mark the symbol
            if ( defined $symbol_productive ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::PRODUCTIVE]
                    = $symbol_productive;
                $work_to_do++;
                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

    }    # work_to_do loop

}

sub nulling {
    my $grammar = shift;

    my ( $rules, $symbols ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
    ];

    my $symbol_work_set = [];
    $#$symbol_work_set = $#$symbols;
    my $rule_work_set = [];
    $#$rule_work_set = $#$rules;

    for my $rule_id (
        map  { $_->[Parse::Marpa::Internal::Rule::ID] }
        grep { $_->[Parse::Marpa::Internal::Rule::NULLING] } @$rules
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }

    for my $symbol_id (
        map  { $_->[Parse::Marpa::Internal::Symbol::ID] }
        grep { $_->[Parse::Marpa::Internal::Symbol::NULLING] } @$symbols
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }

    my $work_to_do = 1;

    while ($work_to_do) {
        $work_to_do = 0;

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#$rule_work_set ) )
        {
            my $work_rule = $rules->[$rule_id];
            $rule_work_set->[$rule_id] = 0;
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already is marked one way or the other
            next RULE
                if defined
                    $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLING];

            # assume nulling until we hit an unmarked or non-nulling symbol
            my $symbol_nulling = 1;

            # make sure that all rules for this lhs are nulling
            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $nulling = $rule->[Parse::Marpa::Internal::Rule::NULLING];

                # unmarked rule, change the assumption for the symbol to undef,
                # but keep scanning for rule marked non-nulling,
                # which will override everything else
                if ( not defined $nulling ) {
                    $symbol_nulling = undef;
                    next LHS_RULE;
                }

                # any non-nulling rule means the LHS is not nulling
                if ( $nulling == 0 ) {
                    $symbol_nulling = 0;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol nulling or non-nulling
            #  mark the symbol
            if ( defined $symbol_nulling ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLING] =
                    $symbol_nulling;
                $work_to_do++;

                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#$symbol_work_set ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;

            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];
            PRODUCING_RULE: for my $rule (@$rules_producing) {

                # no work to do -- this rule already has nulling marked
                next PRODUCING_RULE
                    if defined $rule->[Parse::Marpa::Internal::Rule::NULLING];

                # assume nulling until we hit an unmarked or non-nulling symbol
                my $rule_nulling = 1;

                # are all symbols on the RHS of this rule marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $nulling = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::NULLING];

                    # unmarked rule, change the assumption for rule to undef,
                    # but keep scanning for non-nulling
                    # rule, which will override everything else
                    if ( not defined $nulling ) {
                        $rule_nulling = undef;
                        next RHS_SYMBOL;
                    }

                    # any non-nulling RHS symbol means the rule is non-nulling
                    if ( $nulling == 0 ) {
                        $rule_nulling = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule nulling or non-nulling, mark the rule
                if ( defined $rule_nulling ) {
                    $rule->[Parse::Marpa::Internal::Rule::NULLING] =
                        $rule_nulling;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

    }    # work_to_do loop

}

# returns undef if there was a problem
sub nullable {
    my $grammar = shift;
    my ( $rules, $symbols, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    }

    # boolean to track if current pass has changed anything
    my $work_to_do = 1;

    my $symbol_work_set = [];
    $#$symbol_work_set = @$symbols;
    my $rule_work_set = [];
    $#$rule_work_set = @$rules;

    for my $symbol_id (
        map { $_->[Parse::Marpa::Internal::Symbol::ID] }
        grep {
                   $_->[Parse::Marpa::Internal::Symbol::NULLABLE]
                or $_->[Parse::Marpa::Internal::Symbol::NULLING]
        } @$symbols
        )
    {
        $symbol_work_set->[$symbol_id] = 1;
    }
    for my $rule_id (
        map  { $_->[Parse::Marpa::Internal::Rule::ID] }
        grep { defined $_->[Parse::Marpa::Internal::Rule::NULLABLE] } @$rules
        )
    {
        $rule_work_set->[$rule_id] = 1;
    }

    while ($work_to_do) {
        $work_to_do = 0;

        SYMBOL_PASS:
        for my $symbol_id ( grep { $symbol_work_set->[$_] }
            ( 0 .. $#$symbol_work_set ) )
        {
            my $work_symbol = $symbols->[$symbol_id];
            $symbol_work_set->[$symbol_id] = 0;
            my $rules_producing =
                $work_symbol->[Parse::Marpa::Internal::Symbol::RHS];

            PRODUCING_RULE: for my $rule (@$rules_producing) {

                # assume nullable until we hit an unmarked or non-nullable symbol
                my $rule_nullable = 1;

                # no work to do -- this rule already has nullability marked
                next PRODUCING_RULE
                    if
                    defined $rule->[Parse::Marpa::Internal::Rule::NULLABLE];

                # are all symbols on the RHS of this rule bottom marked?
                RHS_SYMBOL:
                for my $rhs_symbol (
                    @{ $rule->[Parse::Marpa::Internal::Rule::RHS] } )
                {
                    my $nullable = $rhs_symbol
                        ->[Parse::Marpa::Internal::Symbol::NULLABLE];

                    # unmarked symbol, change the assumption for rule to undef, but keep scanning for non-nullable
                    # symbol, which will override everything else
                    if ( not defined $nullable ) {
                        $rule_nullable = undef;
                        next RHS_SYMBOL;
                    }

                    # any non-nullable RHS symbol means the rule is not nullable
                    if ( $nullable == 0 ) {
                        $rule_nullable = 0;
                        last RHS_SYMBOL;
                    }
                }

                # if this pass found the rule nullable or not, so mark the rule
                if ( defined $rule_nullable ) {
                    $rule->[Parse::Marpa::Internal::Rule::NULLABLE] =
                        $rule_nullable;
                    $work_to_do++;
                    $rule_work_set
                        ->[ $rule->[Parse::Marpa::Internal::Rule::ID] ] = 1;
                }

            }
        }    # SYMBOL_PASS

        RULE:
        for my $rule_id ( grep { $rule_work_set->[$_] }
            ( 0 .. $#$rule_work_set ) )
        {
            my $work_rule  = $rules->[$rule_id];
            my $lhs_symbol = $work_rule->[Parse::Marpa::Internal::Rule::LHS];

            # no work to do -- this symbol already has nullability marked
            next RULE
                if defined
                    $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLABLE];

            # assume non-nullable until we hit an unmarked or non-nullable symbol
            my $symbol_nullable = 0;

            LHS_RULE:
            for my $rule (
                @{ $lhs_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
            {

                my $nullable =
                    $rule->[Parse::Marpa::Internal::Rule::NULLABLE];

                # unmarked symbol, change the assumption for rule to undef,
                # but keep scanning for nullable
                # rule, which will override everything else
                if ( not defined $nullable ) {
                    $symbol_nullable = undef;
                    next LHS_RULE;
                }

                # any nullable rule means the LHS is nullable
                if ( $nullable == 1 ) {
                    $symbol_nullable = 1;
                    last LHS_RULE;
                }
            }

            # if this pass found the symbol nullable or not, mark the symbol
            if ( defined $symbol_nullable ) {
                $lhs_symbol->[Parse::Marpa::Internal::Symbol::NULLABLE] =
                    $symbol_nullable;
                $work_to_do++;
                $symbol_work_set
                    ->[ $lhs_symbol->[Parse::Marpa::Internal::Symbol::ID] ] =
                    1;
            }

        }    # RULE

    }    # work_to_do loop

    my $counted_nullable_count;
    for my $symbol (@$symbols) {
        my ( $name, $nullable, $counted, ) = @{$symbol}[
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::COUNTED,
        ];
        if ( $nullable and $counted ) {
            my $problem = "Nullable symbol $name is on rhs of counted rule";
            push(
                @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
                $problem
            );
            $counted_nullable_count++;
        }
    }
    if ($counted_nullable_count) {
        my $problem =
            "Counted nullables confuse Marpa -- please rewrite the grammar";
        push(
            @{ $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS] },
            $problem
        );
        return;
    }

    return 1;

}

sub detect_cycle {
    my $grammar = shift;
    my ( $rules, $symbols, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
    ];
    my @unit_derivation;

    # initialize the unit derivation matrix from the rules
    RULE: for my $rule (@$rules) {
        next RULE unless $rule->[ Parse::Marpa::Internal::Rule::ACCESSIBLE ];
        next RULE unless $rule->[ Parse::Marpa::Internal::Rule::PRODUCTIVE ];
        my $rhs = $rule->[ Parse::Marpa::Internal::Rule::RHS ];
        my $non_nullable_symbol;
        for my $rhs_symbol (@$rhs) {
            if (not $rhs->[ Parse::Marpa::Internal::Symbol::NULLABLE ]) {

                # if we have two non-nullables on the RHS in this rule,
                # it can never amount to a unit rule and we can ignore it
                next RULE if defined $non_nullable_symbol;

                $non_nullable_symbol = $rhs_symbol;
            }
        } # for $rhs_symbol

        # at this point we must be in a rule with zero or one non-nullable on the RHS

        my $lhs_id
            = $rule ->[ Parse::Marpa::Internal::Rule::LHS ]
                ->[ Parse::Marpa::Internal::Symbol::ID ];

        if (defined $non_nullable_symbol) {
            # if we have one non-nullable symbol, it's the only one that can
            # appear in a unit derivation

            $unit_derivation[$lhs_id]
                [ $non_nullable_symbol->[ Parse::Marpa::Internal::Symbol::ID ] ] 
                = 1;
            next RULE;
        }

        # at this point *ALL* rhs symbols must be nullable, meaning every one
        # of them can be in a unit derivation
        for my $rhs_symbol (@$rhs) {
            $unit_derivation
                [$lhs_id]
                [ $rhs_symbol->[ Parse::Marpa::Internal::Symbol::ID ] ] 
                = 1;
        }

    }

    # Now take the transitive closure of the unit derivation matrix until we
    # either find a cycle, or 
    # complete it without having found a cycle

    my $previous_count = -1;

    CLOSURE_LOOP: while (1) {

        my $current_count = 0;
        my @lhs_ids = grep { exists $unit_derivation[$_] } (0 .. $#$symbols);
        for my $lhs_id (@lhs_ids) {

            my $rhs_vector = $unit_derivation[$lhs_id];
            my @rhs_ids = 
                grep { exists $rhs_vector->[$_]}
                (0 .. $#$symbols);
            $current_count += scalar @rhs_ids;
            my @new_rhs_ids;
            for my $rhs_id (@rhs_ids) {

                # Is this our cycle?
                if ($lhs_id == $rhs_id) {
                    my $symbol_name
                        = $symbols->[$lhs_id]->[Parse::Marpa::Internal::Symbol::NAME];
                    croak(
                        'Cycle in grammar, symbol = ', $symbol_name
                    );
                }
                next unless exists $unit_derivation[$rhs_id];
                my $new_rhs_vector = $unit_derivation[$rhs_id];
                my @new_rhs_ids =
                    grep { exists $new_rhs_vector->[$_]}
                    (0 .. $#$symbols);
                for my $new_rhs_id (@new_rhs_ids) {
                    $unit_derivation[$lhs_id][$new_rhs_id] = 1;
                }
            }
        }

        last CLOSURE_LOOP if $current_count == $previous_count;
        $previous_count = $current_count;

    }

} # sub detect_cycles

sub create_NFA {
    my $grammar = shift;
    my ( $rules, $symbols, $symbol_hash, $start, $academic ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::START,
        Parse::Marpa::Internal::Grammar::ACADEMIC
    ];

    $grammar->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL] =
        [ grep { $_->[Parse::Marpa::Internal::Symbol::NULLABLE] } @$symbols ];

    my $NFA = [];
    $grammar->[Parse::Marpa::Internal::Grammar::NFA] = $NFA;

    my $state_id = 0;
    my @NFA_by_item;

    # create S0
    my $s0 = [];
    @{$s0}[
        Parse::Marpa::Internal::NFA::ID,
        Parse::Marpa::Internal::NFA::NAME,
        Parse::Marpa::Internal::NFA::TRANSITION
        ]
        = ( $state_id++, "S0", {} );
    push( @$NFA, $s0 );

    # create the other states
    RULE: for my $rule (@$rules) {
        my ( $rule_id, $rhs, $useful ) = @{$rule}[
            Parse::Marpa::Internal::Rule::ID,
            Parse::Marpa::Internal::Rule::RHS,
            Parse::Marpa::Internal::Rule::USEFUL
        ];
        next RULE unless $academic or $useful;
        for my $position ( 0 .. scalar @{$rhs} ) {
            my $new_state = [];
            @{$new_state}[
                Parse::Marpa::Internal::NFA::ID,
                Parse::Marpa::Internal::NFA::NAME,
                Parse::Marpa::Internal::NFA::ITEM,
                Parse::Marpa::Internal::NFA::TRANSITION
                ]
                = ( $state_id, "S" . $state_id, [ $rule, $position ], {} );
            $state_id++;
            push( @$NFA, $new_state );
            $NFA_by_item[$rule_id][$position] = $new_state;
        }    # position
    }    # rule

    # now add the transitions
    STATE: for my $state (@$NFA) {
        my ( $id, $name, $item, $transition ) = @$state;

        # transitions from state 0:
        # for every rule with the start symbol on its LHS, the item [ rule, 0 ]
        if ( not defined $item ) {
            my @start_rules =
                @{ $start->[Parse::Marpa::Internal::Symbol::LHS] };
            my $start_alias =
                $start->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
            if ( defined $start_alias ) {
                push(
                    @start_rules,
                    @{  $start_alias->[Parse::Marpa::Internal::Symbol::LHS]
                        }
                );
            }

            RULE: for my $start_rule (@start_rules) {
                my ( $start_rule_id, $useful ) = @{$start_rule}[
                    Parse::Marpa::Internal::Rule::ID,
                    Parse::Marpa::Internal::Rule::USEFUL
                ];
                next RULE unless $useful;
                push(
                    @{ $transition->{""} },
                    $NFA_by_item[$start_rule_id][0]
                );
            }
            next STATE;
        }

        # transitions from states other than state 0:

        my ( $rule, $position ) = @{$item}[
            Parse::Marpa::Internal::LR0_item::RULE,
            Parse::Marpa::Internal::LR0_item::POSITION
        ];
        my $rule_id = $rule->[Parse::Marpa::Internal::Rule::ID];
        my $next_symbol =
            $rule->[Parse::Marpa::Internal::Rule::RHS]->[$position];

        # no transitions if position is after the end of the RHS
        if ( not defined $next_symbol ) { next STATE; }

        # the scanning transition: the transition if the position is at symbol X
        # in the RHS, via symbol X, to the state corresponding to the same
        # rule with the position incremented by 1
        # should I use ID as the key for those hashes, or NAME?
        push(
            @{  $transition
                    ->{ $next_symbol->[Parse::Marpa::Internal::Symbol::NAME] }
                },
            $NFA_by_item[$rule_id][ $position + 1 ]
        );

        # the prediction transitions: transitions if the position is at symbol X
        # in the RHS, via the empty symbol, to all states with X on the LHS and
        # position 0
        RULE:
        for my $predicted_rule (
            @{ $next_symbol->[Parse::Marpa::Internal::Symbol::LHS] } )
        {
            my ( $predicted_rule_id, $useful ) = @{$predicted_rule}[
                Parse::Marpa::Internal::Rule::ID,
                Parse::Marpa::Internal::Rule::USEFUL
            ];
            next RULE unless $useful;
            push(
                @{ $transition->{""} },
                $NFA_by_item[$predicted_rule_id][0]
            );
        }
    }
}

# take a list of kernel NFA states, possibly with duplicates, and return the fully
# built kernel split DFA (SDFA) state.  It builds the kernel state and its associated prediction state,
# as necessary.  The build is complete, except for the non-empty transitions, which are
# left to be set elsewhere.
#

sub assign_SDFA_kernel_state {
    my $grammar       = shift;
    my $kernel_states = shift;
    my ( $NFA_states, $SDFA_by_name, $SDFA ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::NFA,
        Parse::Marpa::Internal::Grammar::SDFA_BY_NAME,
        Parse::Marpa::Internal::Grammar::SDFA
    ];

    my $kernel_NFA_state_seen     = [];
    my $prediction_NFA_state_seen = [];

    # the two split DFA states which we are to find or create.  The kernel SDFA state is the
    # return value.
    my $kernel_SDFA_state;
    my $prediction_SDFA_state;

    # pre-allocate the arrays that track whether we've already used an NFA state
    $#$kernel_NFA_state_seen = $#$prediction_NFA_state_seen = @$NFA_states;

    # lists of NFA states to followed up on for the closure
    my $kernel_work_list = [
        grep {
            not $kernel_NFA_state_seen
                ->[ $_->[Parse::Marpa::Internal::NFA::ID] ]++
            } @$kernel_states
    ];
    my $prediction_work_list = [];

    # create the kernel SDFA state
    WORK_LIST: while (@$kernel_work_list) {
        my $next_work_list = [];

        NFA_STATE: for my $NFA_state (@$kernel_work_list) {

            my $to_states =
                $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION]->{""};

            # First the empty transitions.  These will all be predictions,
            # and need to go into the
            # work list for the prediction SDFA state
            if ( defined $to_states ) {
                push(
                    @$prediction_work_list,
                    grep {
                        not $prediction_NFA_state_seen
                            ->[ $_->[Parse::Marpa::Internal::NFA::ID] ]++
                        } @$to_states
                );
            }

            SYMBOL:
            for my $nullable_symbol (
                @{  $grammar
                        ->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL]
                }
                )
            {
                $to_states =
                    $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION]
                    ->{ $nullable_symbol
                        ->[Parse::Marpa::Internal::Symbol::NAME] };
                next SYMBOL unless defined $to_states;
                push(
                    @$next_work_list,
                    grep {
                        not $kernel_NFA_state_seen
                            ->[ $_->[Parse::Marpa::Internal::NFA::ID] ]++
                        } @$to_states
                );
            }
        }

        $kernel_work_list = $next_work_list;
    }    # kernel WORK_LIST

    my $NFA_ids = [];
    NFA_ID: for ( my $NFA_id = 0; $NFA_id <= $#$NFA_states; $NFA_id++ ) {
        next NFA_ID unless $kernel_NFA_state_seen->[$NFA_id];
        my $LR0_item =
            $NFA_states->[$NFA_id]->[Parse::Marpa::Internal::NFA::ITEM];
        my ( $rule, $position ) = @{$LR0_item}[
            Parse::Marpa::Internal::LR0_item::RULE,
            Parse::Marpa::Internal::LR0_item::POSITION
        ];
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];
        if ( $position < @$rhs ) {
            my $next_symbol = $rhs->[$position];
            next NFA_ID
                if $next_symbol->[Parse::Marpa::Internal::Symbol::NULLING];
        }
        push( @$NFA_ids, $NFA_id );
    }
    my $kernel_SDFA_name = join( ",", @$NFA_ids );

    $kernel_SDFA_state = $SDFA_by_name->{$kernel_SDFA_name};

    # if we already built the kernel SDFA state, we have also already built any necessary prediction SDFA
    # state and linked it, so we're done
    return $kernel_SDFA_state if defined $kernel_SDFA_state;

    # build the kernel state except for the transitions.
    @{$kernel_SDFA_state}[
        Parse::Marpa::Internal::SDFA::ID,
        Parse::Marpa::Internal::SDFA::NAME,
        Parse::Marpa::Internal::SDFA::NFA_STATES
        ]
        = ( scalar @$SDFA, $kernel_SDFA_name, [ @{$NFA_states}[@$NFA_ids] ],
        );
    push( @$SDFA, $kernel_SDFA_state );
    $SDFA_by_name->{$kernel_SDFA_name} = $kernel_SDFA_state;

    # if there is no prediction half of the split DFA state, we are done.
    return $kernel_SDFA_state unless @$prediction_work_list;

    # there is a prediction state, so find its canonical name
    WORK_LIST: while (@$prediction_work_list) {
        my $next_work_list = [];

        NFA_STATE: for my $NFA_state (@$prediction_work_list) {

            SYMBOL:
            for my $symbol_name (
                "",
                map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @{
                    $grammar
                        ->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL]
                }
                )
            {
                my $to_states =
                    $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION]
                    ->{$symbol_name};
                next SYMBOL unless defined $to_states;
                push(
                    @$next_work_list,
                    grep {
                        not $prediction_NFA_state_seen
                            ->[ $_->[Parse::Marpa::Internal::NFA::ID] ]++
                        } @$to_states
                );
            }
        }

        $prediction_work_list = $next_work_list;
    }    # kernel WORK_LIST

    $NFA_ids = [];
    NFA_ID: for ( my $NFA_id = 0; $NFA_id <= $#$NFA_states; $NFA_id++ ) {
        next NFA_ID unless $prediction_NFA_state_seen->[$NFA_id];
        my $LR0_item =
            $NFA_states->[$NFA_id]->[Parse::Marpa::Internal::NFA::ITEM];
        my ( $rule, $position ) = @{$LR0_item}[
            Parse::Marpa::Internal::LR0_item::RULE,
            Parse::Marpa::Internal::LR0_item::POSITION
        ];
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];
        if ( $position < @$rhs ) {
            my $next_symbol = $rhs->[$position];
            next NFA_ID
                if $next_symbol->[Parse::Marpa::Internal::Symbol::NULLING];
        }
        push( @$NFA_ids, $NFA_id );
    }
    my $prediction_SDFA_name = join( ",", @$NFA_ids );

    $prediction_SDFA_state = $SDFA_by_name->{$prediction_SDFA_name};

    # if we have not already built the prediction SDFA state, build it
    if ( not defined $prediction_SDFA_state ) {

        # build the prediction state except for the transitions.
        @{$prediction_SDFA_state}[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::NAME,
            Parse::Marpa::Internal::SDFA::NFA_STATES
            ]
            = (
            scalar @$SDFA,
            $prediction_SDFA_name, [ @{$NFA_states}[@$NFA_ids] ],
            );
        push( @$SDFA, $prediction_SDFA_state );
        $SDFA_by_name->{$prediction_SDFA_name} = $prediction_SDFA_state;

    }

    # add the empty transition from kernel SDFA state to prediction SDFA state
    $kernel_SDFA_state->[Parse::Marpa::Internal::SDFA::TRANSITION]->{""} =
        $prediction_SDFA_state;

    # return the kernel SDFA state
    $kernel_SDFA_state;
}

sub create_SDFA {
    my $grammar = shift;
    my ( $symbols, $symbol_hash, $NFA, $start, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::NFA,
        Parse::Marpa::Internal::Grammar::START,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
    }

    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA] = [];
    my $NFA_s0 = $NFA->[0];

    # next SDFA state to compute transitions for
    my $next_state_id = 0;

    my $initial_NFA_states =
        $NFA_s0->[Parse::Marpa::Internal::NFA::TRANSITION]->{""};
    if ( not defined $initial_NFA_states ) {
        say $trace_fh "Empty NFA, cannot create SDFA";
        return;
    }
    assign_SDFA_kernel_state( $grammar, $initial_NFA_states );

    while ( $next_state_id < scalar @$SDFA ) {

        # compute the SDFA state transitions from the transitions
        # of the NFA states of which it is composed
        my $NFA_to_states_by_symbol = {};

        my $SDFA_state = $SDFA->[ $next_state_id++ ];

        # aggregrate the transitions, by symbol, for every NFA state in this SDFA
        # state
        for my $NFA_state (
            @{ $SDFA_state->[Parse::Marpa::Internal::SDFA::NFA_STATES] } )
        {
            my $transition =
                $NFA_state->[Parse::Marpa::Internal::NFA::TRANSITION];
            NFA_TRANSITION:
            while ( my ( $symbol, $to_states ) = each(%$transition) ) {
                next NFA_TRANSITION if $symbol eq "";
                push( @{ $NFA_to_states_by_symbol->{$symbol} }, @$to_states );
            }
        }    # $NFA_state

        # for each transition symbol, create the transition to the SDFA kernel state
        while ( my ( $symbol, $to_states ) = each(%$NFA_to_states_by_symbol) )
        {
            $SDFA_state->[Parse::Marpa::Internal::SDFA::TRANSITION]
                ->{$symbol} =
                assign_SDFA_kernel_state( $grammar, $to_states );
        }
    }

    # For the parse phase, pre-compute the list of names of the lhs's of
    # complete items, the list of complete items, and the start rule (should
    # be maximum one per state)
    STATE: for my $state (@$SDFA) {
        my $lhs_list       = [];
        my $complete_rules = [];
        my $start_rule     = undef;
        $#$lhs_list = @$symbols;
        my $NFA_states = $state->[Parse::Marpa::Internal::SDFA::NFA_STATES];
        for my $NFA_state (@$NFA_states) {
            my $item = $NFA_state->[Parse::Marpa::Internal::NFA::ITEM];
            my ( $rule, $position ) = @{$item}[
                Parse::Marpa::Internal::LR0_item::RULE,
                Parse::Marpa::Internal::LR0_item::POSITION
            ];
            my ( $lhs, $rhs ) = @{$rule}[
                Parse::Marpa::Internal::Rule::LHS,
                Parse::Marpa::Internal::Rule::RHS
            ];
            if ( $position >= @$rhs ) {
                my ( $lhs_id, $lhs_is_start ) = @{$lhs}[
                    Parse::Marpa::Internal::Symbol::ID,
                    Parse::Marpa::Internal::Symbol::START
                ];
                $lhs_list->[$lhs_id] = 1;
                push( @{ $complete_rules->[$lhs_id] }, $rule );
                $start_rule = $rule if $lhs_is_start;
            }
        }    # NFA_state
        $state->[Parse::Marpa::Internal::SDFA::START_RULE] = $start_rule;
        $state->[Parse::Marpa::Internal::SDFA::COMPLETE_RULES] =
            $complete_rules;
        $state->[Parse::Marpa::Internal::SDFA::COMPLETE_LHS] =
            [ map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
                @{$symbols}[ grep { $lhs_list->[$_] } ( 0 .. $#$lhs_list ) ]
            ];

    }    # STATE
}

sub setup_academic_grammar {
    my $grammar = shift;
    my $rules   = $grammar->[Parse::Marpa::Internal::Grammar::RULES];

    # in an academic grammar, consider all rules useful
    for my $rule (@$rules) {
        $rule->[Parse::Marpa::Internal::Rule::USEFUL] = 1;
    }
}

# given a nullable symbol, create a nulling alias and make the first symbol non-nullable
sub alias_symbol {
    my $grammar         = shift;
    my $nullable_symbol = shift;
    my ( $symbol, $symbols, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
    ];
    my ( $accessible, $productive, $name, $null_value ) =
        @{$nullable_symbol}[
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
        ];

    # create the new, nulling symbol
    my $symbol_count = @$symbols;
    my $alias_name =
        $nullable_symbol->[Parse::Marpa::Internal::Symbol::NAME] . "[]";
    my $alias = [];
    @{$alias}[
        Parse::Marpa::Internal::Symbol::ID,
        Parse::Marpa::Internal::Symbol::NAME,
        Parse::Marpa::Internal::Symbol::LHS,
        Parse::Marpa::Internal::Symbol::RHS,
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::NULLING,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
        ]
        = (
        $symbol_count, $alias_name, [], [], $accessible,
        $productive, 1, 1, $null_value
        );
    push( @$symbols, $alias );
    weaken( $symbol->{$alias_name} = $alias );

    # turn the original symbol into a non-nullable with a reference to the new alias
    @{$nullable_symbol}[
        Parse::Marpa::Internal::Symbol::NULLABLE,
        Parse::Marpa::Internal::Symbol::NULL_ALIAS
        ]
        = ( 0, $alias );
    $alias;
}

# For efficiency, steps in the CHAF evaluation
# work on a last-is-rest principle -- productions
# with a CHAF head always return reference to an array
# of values, of which the last value is (in turn)
# a reference to an array with the "rest" of the values.
# An empty array signals that there are no more.

# rewrite as Chomsky-Horspool-Aycock Form
sub rewrite_as_CHAF {
    my $grammar = shift;
    my ( $rules, $symbols, $old_start_symbol ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::START,
    ];

    # add null aliases to symbols which need them
    my $symbol_count = @$symbols;
    SYMBOL: for ( my $ix = 0; $ix < $symbol_count; $ix++ ) {
        my $symbol = $symbols->[$ix];
        my ( $productive, $accessible, $nulling, $nullable,
            $null_alias )
            = @{$symbol}[
            Parse::Marpa::Internal::Symbol::PRODUCTIVE,
            Parse::Marpa::Internal::Symbol::ACCESSIBLE,
            Parse::Marpa::Internal::Symbol::NULLING,
            Parse::Marpa::Internal::Symbol::NULLABLE,
            Parse::Marpa::Internal::Symbol::NULL_ALIAS
            ];

        # not necessary is the symbol already has a null
        # alias
        next SYMBOL if $null_alias;

        #  we don't bother with unreachable symbols
        next SYMBOL unless $productive;
        next SYMBOL unless $accessible;

        # look for proper nullable symbols
        next SYMBOL if $nulling;
        next SYMBOL unless $nullable;

        alias_symbol( $grammar, $symbol );
    }

    # mark, or create as needed, the useful rules

    # get the initial rule count -- new rules will be added and we don't iterate
    # over them
    my $rule_count = @$rules;
    RULE: for ( my $rule_id = 0; $rule_id < $rule_count; $rule_id++ ) {
        my $rule = $rules->[$rule_id];
        my ( $lhs, $rhs, $productive, $accessible, $nulling,
            $nullable, $priority )
            = @{$rule}[
            Parse::Marpa::Internal::Rule::LHS,
            Parse::Marpa::Internal::Rule::RHS,
            Parse::Marpa::Internal::Rule::PRODUCTIVE,
            Parse::Marpa::Internal::Rule::ACCESSIBLE,
            Parse::Marpa::Internal::Rule::NULLING,
            Parse::Marpa::Internal::Rule::NULLABLE,
            Parse::Marpa::Internal::Rule::PRIORITY,
            ];

        # unreachable and nulling rules are useless
        next RULE unless $productive;
        next RULE unless $accessible;
        next RULE if $nulling;

        # Keep track of whether the lhs side of any new rules we create should
        # be nullable.  If any symbol in a production is not nullable, the lhs
        # is not nullable.  If the original production is nullable, all symbols
        # are nullable, all subproductions will be, and all new lhs's should be.
        # But even if the original production is not nullable, some of the
        # subproductions may be.  These will always be in a series starting from
        # the far right.

        # Going from right to left,
        # once the first non-nullable symbol is encountered,
        # that subproduction is non-nullable,
        # that lhs will be non-nullable, and since that
        # new lhs is on the far rhs of subsequent (going left) subproductions,
        # all subsequent subproductions and their lhs's will be non-nullable.
        #
        # Finally, in one more complication, remember that the nullable flag
        # was unset if a nullable was aliased.  So we need to check both the
        # NULL_ALIAS (for proper nullables) and the NULLING flags to see if
        # the original rule was nullable.

        my $last_nonnullable = -1;
        my $proper_nullables = [];
        RHS_SYMBOL: for ( my $ix = 0; $ix <= $#$rhs; $ix++ ) {
            my $symbol = $rhs->[$ix];
            my ( $null_alias, $nulling, $null_value ) = @{$symbol}[
                Parse::Marpa::Internal::Symbol::NULL_ALIAS,
                Parse::Marpa::Internal::Symbol::NULLING,
                Parse::Marpa::Internal::Symbol::NULL_VALUE,
            ];
            next RHS_SYMBOL if $nulling;
            if ($null_alias) {
                push( @$proper_nullables, $ix );
                next RHS_SYMBOL;
            }
            $last_nonnullable = $ix;
        }

        # we found no properly nullable symbols in the RHS, so this rule is useful without
        # any changes
        if ( @$proper_nullables == 0 ) {
            $rule->[Parse::Marpa::Internal::Rule::USEFUL] = 1;
            next RULE;
        }

        # The left hand side of the first subproduction is the lhs of the original rule
        my $subp_lhs   = $lhs;
        my $subp_start = 0;

        # break this production into subproductions with a fixed number of proper nullables,
        # then factor out the proper nullables into a set of productions
        # with only non-nullable and nulling symbols.
        SUBPRODUCTION: for ( ;; ) {

            my $subp_end;
            my $proper_nullable0      = $proper_nullables->[0];
            my $subp_proper_nullable0 = $proper_nullable0 - $subp_start;
            my $proper_nullable1;
            my $subp_proper_nullable1;
            my $subp_factor0_rhs;
            my $next_subp_lhs;

            SETUP_SUBPRODUCTION: {

                if ( @$proper_nullables == 1 ) {
                    $subp_end = $#$rhs;
                    $subp_factor0_rhs =
                        [ @{$rhs}[ $subp_start .. $subp_end ] ];
                    $proper_nullables = [];
                    last SETUP_SUBPRODUCTION;
                }

                $proper_nullable1      = $proper_nullables->[1];
                $subp_proper_nullable1 = $proper_nullable1 - $subp_start;

                if ( @$proper_nullables == 2 ) {
                    $subp_end = $#$rhs;
                    $subp_factor0_rhs =
                        [ @{$rhs}[ $subp_start .. $subp_end ] ];
                    $proper_nullables = [];
                    last SETUP_SUBPRODUCTION;
                }

                # The following subproduction is non-nullable.
                # TODO: Has this code been tried yet? ( 15 Jan 2008)
                if ( $proper_nullable1 < $last_nonnullable ) {
                    $subp_end = $proper_nullable1;
                    splice( @$proper_nullables, 0, 2 );

                    my $unique_name_piece
                        = sprintf(
                            "[x%x]", 
                            (scalar @{$grammar->[ Parse::Marpa::Internal::Grammar::SYMBOLS]})
                        );
                    $next_subp_lhs = assign_symbol(
                        $grammar,
                        $lhs->[Parse::Marpa::Internal::Symbol::NAME]
                            . "[R"
                            . $rule_id . ":"
                            . ( $subp_end + 1 )
                            . "]"
                            . $unique_name_piece
                    );
                    @{$next_subp_lhs}[
                        Parse::Marpa::Internal::Symbol::NULLABLE,
                        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
                        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
                        Parse::Marpa::Internal::Symbol::NULLING,
                        ]
                        = ( 0, 1, 1, 0 );
                    $subp_factor0_rhs = [
                        @{$rhs}[ $subp_start .. $subp_end ],
                        $next_subp_lhs
                    ];
                    last SETUP_SUBPRODUCTION;
                }

                # if we got this far we have 3 or more proper nullables, and the next
                # subproduction is nullable
                $subp_end = $proper_nullable1 - 1;
                shift @$proper_nullables;

                my $unique_name_piece
                    = sprintf(
                        "[x%x]", 
                        (scalar @{$grammar->[ Parse::Marpa::Internal::Grammar::SYMBOLS]})
                    );
                $next_subp_lhs = assign_symbol(
                    $grammar,
                    $lhs->[Parse::Marpa::Internal::Symbol::NAME]
                        . "[R"
                        . $rule_id . ":"
                        . ( $subp_end + 1 )
                        . "]"
                        . $unique_name_piece
                );
                @{$next_subp_lhs}[
                    Parse::Marpa::Internal::Symbol::NULLABLE,
                    Parse::Marpa::Internal::Symbol::ACCESSIBLE,
                    Parse::Marpa::Internal::Symbol::PRODUCTIVE,
                    Parse::Marpa::Internal::Symbol::NULLING,
                    # Parse::Marpa::Internal::Symbol::NULL_VALUE,
                    ]
                    = (
                    1, 1, 1, 0,
                    # [   @{$rhs_null_value}
                            # [ ( $subp_end + 1 ) .. $#$rhs_null_value ],
                        # []
                    # ],
                    );
                my $nulling_subp_lhs = alias_symbol( $grammar, $next_subp_lhs );
                $nulling_subp_lhs->[ Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING ]
                    = [ @{$rhs}[ ( $subp_end + 1 ) .. $#$rhs ] ];
                $subp_factor0_rhs =
                    [ @{$rhs}[ $subp_start .. $subp_end ], $next_subp_lhs ];

            }    # SETUP_SUBPRODUCTION

            my $factored_rhs = [$subp_factor0_rhs];

            FACTOR: {

                # We have additional factored productions if
                # 1) there is more than one proper nullable;
                # 2) there's only one, but replacing it with a nulling symbol will
                #    not make the entire production nulling
                #
                # Here and below we use the nullable flag to establish whether a
                # factored subproduction rhs would be nulling, on this principle:
                #
                # If substituting nulling symbols for all proper nullables does not
                # make a production nulling, then it is not nullable, and vice versa.

                last FACTOR if $nullable and not defined $proper_nullable1;

                # The second factored production, with a nulling symbol substituted for
                # the first proper nullable.
                # and nulling it would make this factored subproduction nulling, don't
                # bother.
                $factored_rhs->[1] = [@$subp_factor0_rhs];
                $factored_rhs->[1]->[$subp_proper_nullable0] =
                    $subp_factor0_rhs->[$subp_proper_nullable0]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

                # The third factored production, with a nulling symbol replacing the
                # second proper nullable.  Make sure there ARE two proper nullables.
                last FACTOR unless defined $proper_nullable1;
                $factored_rhs->[2] = [@$subp_factor0_rhs];
                $factored_rhs->[2]->[$subp_proper_nullable1] =
                    $subp_factor0_rhs->[$subp_proper_nullable1]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

                # The fourth and last factored production, with a nulling symbol replacing
                # both proper nullables.  We don't include it if it results in a nulling
                # production.
                last FACTOR if $nullable;
                $factored_rhs->[3] = [ @{ $factored_rhs->[2] } ];
                $factored_rhs->[3]->[$subp_proper_nullable0] =
                    $subp_factor0_rhs->[$subp_proper_nullable0]
                    ->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];

            }    # FACTOR

            for ( my $ix = 0; $ix <= $#$factored_rhs; $ix++ ) {
                my $factor_rhs = $factored_rhs->[$ix];

                # No need to bother putting together values
                # if the rule's closure is not defined
                # and the values would all be discarded

                # figure out which closure to use
                # if the LHS is the not LHS of the original rule, we have a
                # special CHAF header
                my $has_chaf_lhs = ( $subp_lhs != $lhs );

                # if a CHAF LHS was created for the next subproduction,
                # there is a CHAF continuation for this subproduction.
                # It applies to this factor if there is one of the first two
                # factors of more than two.
                my $has_chaf_rhs = $next_subp_lhs;

                my $new_rule =
                    add_rule( $grammar, $subp_lhs, $factor_rhs, undef, $priority );
                @{$new_rule}[
                    Parse::Marpa::Internal::Rule::USEFUL,
                    Parse::Marpa::Internal::Rule::ACCESSIBLE,
                    Parse::Marpa::Internal::Rule::PRODUCTIVE,
                    Parse::Marpa::Internal::Rule::NULLABLE,
                    Parse::Marpa::Internal::Rule::NULLING,
                    Parse::Marpa::Internal::Rule::HAS_CHAF_LHS,
                    Parse::Marpa::Internal::Rule::HAS_CHAF_RHS,
                    ]
                    = (
                    1, 1, 1, 0, 0,
                    $has_chaf_lhs,
                    $has_chaf_rhs,
                    );

                $new_rule->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE] =
                    $rule;
                $new_rule->[Parse::Marpa::Internal::Rule::ACTION] =
                    $rule->[Parse::Marpa::Internal::Rule::ACTION];

            }    # for each factored rhs

            # no more
            last SUBPRODUCTION unless $next_subp_lhs;
            $subp_lhs   = $next_subp_lhs;
            $subp_start = $subp_end + 1;
            $nullable   = $subp_start > $last_nonnullable;

        }    # SUBPRODUCTION

    }    # RULE

    # Create a new start symbol
    my ( $productive, $null_value ) = @{$old_start_symbol}[
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
    ];
    my $new_start_symbol =
        assign_symbol( $grammar,
        $old_start_symbol->[Parse::Marpa::Internal::Symbol::NAME] . "[']" );
    @{$new_start_symbol}[
        Parse::Marpa::Internal::Symbol::PRODUCTIVE,
        Parse::Marpa::Internal::Symbol::ACCESSIBLE,
        Parse::Marpa::Internal::Symbol::START,
        Parse::Marpa::Internal::Symbol::NULL_VALUE,
        ]
        = ( $productive, 1, 1, $null_value );

    # Create a new start rule
    my $new_start_rule =
        add_rule( $grammar, $new_start_symbol, [$old_start_symbol], undef, 0 );
    @{$new_start_rule}[
        Parse::Marpa::Internal::Rule::PRODUCTIVE,
        Parse::Marpa::Internal::Rule::ACCESSIBLE,
        Parse::Marpa::Internal::Rule::USEFUL,
        Parse::Marpa::Internal::Rule::ACTION,
        ]
        = ( $productive, 1, 1, q{ $Parse::Marpa::Read_Only::v->[0] } );

    # If we created a null alias for the original start symbol, we need
    # to create a nulling start rule
    my $old_start_alias =
        $old_start_symbol->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
    if ($old_start_alias) {
        my $new_start_alias = alias_symbol( $grammar, $new_start_symbol );
        @{$new_start_alias}[ Parse::Marpa::Internal::Symbol::START, ] = (1);
        my $new_start_rule = add_rule( $grammar, $new_start_alias, [], undef, 0 );

        # Nulling rules are not considered useful, but the top-level one is an exception
        @{$new_start_rule}[
            Parse::Marpa::Internal::Rule::PRODUCTIVE,
            Parse::Marpa::Internal::Rule::ACCESSIBLE,
            Parse::Marpa::Internal::Rule::USEFUL,
            ]
            = ( $productive, 1, 1, );
    }
    $grammar->[Parse::Marpa::Internal::Grammar::START] = $new_start_symbol;
}

package Parse::Marpa::Internal::Earley_item;

# Elements of the EARLEY ITEM structure
# Note that these are Earley items as modified by Aycock & Horspool, with SDFA states instead of
# LR(0) items.
#
use constant STATE => 0;    # the SDFA state
use constant PARENT =>
    1;    # the number of the Earley set with the parent item(s)
use constant TOKENS => 2;    # a list of the links from token scanning
use constant LINKS  => 3;    # a list of the links from the completer step
use constant SET    => 4;    # the set this item is in, for debugging
     # these next elements are "notations" for iterating over the parses
use constant POINTER      => 5;     # symbol just before pointer
use constant RULES        => 6;     # current list of rules
use constant RULE_CHOICE  => 7;     # current choice of rule
use constant LINK_CHOICE  => 8;     # current choice of link
use constant TOKEN_CHOICE => 9;     # current choice of token
use constant VALUE        => 10;    # value of pointer symbol
use constant PREDECESSOR  => 11;    # the predecessor link, if we have a value
use constant SUCCESSOR    => 12;    # the predecessor link, in reverse
use constant EFFECT       => 13;    # the cause link, in reverse
                                    # or the "parent" item
use constant LHS          => 14;    # LHS symbol

# Note that (at least right now) items either have a SUCCESSOR
# or an EFFECT, never both.

package Parse::Marpa::Internal::Parse;

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

my $parse_number = 0;

# Elements of the PARSE structure
use constant GRAMMAR       => 0;    # the grammar used
use constant CURRENT_SET   => 1;    # index of the first incomplete Earley set
use constant EARLEY_SETS   => 2;    # the array of the Earley sets
use constant EARLEY_HASHES => 3;    # the array of hashes used
                                    # to build the Earley sets
use constant CURRENT_PARSE_SET => 4;   # the set being taken as the end of
                                       # parse for an evaluation
                                       # only undef if there are no evaluation
                                       # notations in the earley items
use constant START_ITEM => 5;    # the start item for the current evaluation
use constant FURTHEST_EARLEME         => 7;    # last earley set with a token
use constant EXHAUSTED                => 8;    # parse can't continue?
use constant DEFAULT_PARSE_SET        => 14;
use constant PACKAGE       => 17;              # special "safe" namespace
use constant LEXERS            => 22;    # an array, indexed by symbol id,
                                         # of the lexer for each symbol
use constant LEXABLES_BY_STATE => 23;    # an array, indexed by SDFA state id,
                                         # of the lexables belonging in it
use constant PRIORITIES        => 24;    # an array, indexed by SDFA state id,
                                         # of its priority
use constant LAST_COMPLETED_SET => 26;   # last earley set completed
use constant PARSE_COUNT        => 27;   # number of parses in an ambiguous parse

# Given symbol, returns null value, calculating it
# if necessary.
#
# Assumes all but CHAF values have already been set
sub set_null_symbol_value {
    my $symbol = shift;

    # if it's not a CHAF nulling symbol,
    # or the value is already set, use what we have
    my $chaf_nulling = $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
    my $null_value = $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE];
    if (not $chaf_nulling or defined $null_value) {
        return $null_value;
    }

    $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
        = [ (map { set_null_symbol_value($_) } @$chaf_nulling), [] ];

} # null symbol value

sub set_null_values {
    my $grammar        = shift;
    my $package        = shift;

    my (
        $rules, $symbols, $tracing, $default_null_value
    )  = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE,
    ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_actions = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ACTIONS ];
    }

    SYMBOL: for my $symbol (@$symbols) {
        next SYMBOL if $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
            = $default_null_value;
    }

    # Before tackling the CHAF symbols, set null values specified in
    # empty rules.
    RULE: for my $rule (@$rules) {

        my $action = $rule->[Parse::Marpa::Internal::Rule::ACTION];

        # Set the null value of symbols from the action for their
        # empty rules
        my $rhs = $rule->[Parse::Marpa::Internal::Rule::RHS];

        # Empty rule with action?
        if (defined $action and @$rhs <= 0) {
            my $lhs = $rule->[Parse::Marpa::Internal::Rule::LHS];
            my $nulling_alias = $lhs->[Parse::Marpa::Internal::Symbol::NULL_ALIAS];
            next rule unless defined $nulling_alias;

            local ($Parse::Marpa::Read_Only::v) = [];
            my $code = "package " . $package . ";\n" . $action;
            my @warnings;
            local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
            my $null_value = eval($code);
            my $fatal_error = $@;
            if ($fatal_error or @warnings) {
                die_on_problems($fatal_error, \@warnings,
                    "evaluating null value",
                    "evaluating null value for "
                        . $nulling_alias->[Parse::Marpa::Internal::Symbol::NAME],
                    \$action
                );
            }
            $nulling_alias->[Parse::Marpa::Internal::Symbol::NULL_VALUE] = $null_value;

            if ($trace_actions) {
                print $trace_fh "Setting null value for symbol ",
                    $nulling_alias->[Parse::Marpa::Internal::Symbol::NAME],
                    " from\n", $code, "\n",
                    " to ",
                    Parse::Marpa::show_value(\$null_value),
                    "\n";
            }

        }

    } # RULE

    SYMBOL: for my $symbol (@$symbols) {
        next SYMBOL unless $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];
        $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]
            = set_null_symbol_value($symbol);
    }

    if ($trace_actions) {
        SYMBOL: for my $symbol (@$symbols) {
            next SYMBOL unless $symbol->[Parse::Marpa::Internal::Symbol::IS_CHAF_NULLING];

            print $trace_fh "Setting null value for CHAF symbol ",
                $symbol->[Parse::Marpa::Internal::Symbol::NAME],
                " to ",
                Dumper( $symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE]),
                ;
        }
    }

} # set_null_values

# Set rule actions
sub set_actions {
    my $grammar        = shift;
    my $package        = shift;

    my (
        $rules, $symbols, $symbol_hash, $SDFA, $tracing,
        $default_prefix,
        $default_suffix,
        $default_action,
    ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::RULES,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::SYMBOL_HASH,
        Parse::Marpa::Internal::Grammar::SDFA,
        Parse::Marpa::Internal::Grammar::TRACING,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_ACTION,
    ];

    my $trace_fh;
    my $trace_actions;
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_actions = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ACTIONS ];
    }

    RULE: for my $rule (@$rules) {

        next RULE unless $rule->[Parse::Marpa::Internal::Rule::USEFUL];

        my $action = $rule->[Parse::Marpa::Internal::Rule::ACTION];

        ACTION: {

            $action //= $default_action;
            last ACTION unless defined $action;

            # HAS_CHAF_RHS and HAS_CHAF_LHS would work well as a bit
            # mask in a C implementation
            my $has_chaf_lhs =
                $rule->[Parse::Marpa::Internal::Rule::HAS_CHAF_LHS];
            my $has_chaf_rhs =
                $rule->[Parse::Marpa::Internal::Rule::HAS_CHAF_RHS];

            last ACTION unless $has_chaf_lhs or $has_chaf_rhs;

            if ( $has_chaf_rhs and $has_chaf_lhs ) {
                $action = q{ $Parse::Marpa::Read_Only::v };
                last ACTION;
            }

            # At this point has chaf rhs or lhs but not both
            if ($has_chaf_lhs) {

                $action = q{
                        push(@$Parse::Marpa::Read_Only::v, []);
                        $Parse::Marpa::Read_Only::v;
                    };
                last ACTION;

            }

            # at this point must have chaf rhs and not a chaf lhs

            my $original_rule = $Parse::Marpa::Read_Only::rule
                ->[Parse::Marpa::Internal::Rule::ORIGINAL_RULE];

            $action = q{
                TAIL: for (;;) {
                    my $tail = pop @$Parse::Marpa::Read_Only::v;
                    last TAIL unless scalar @$tail;
                    push(@$Parse::Marpa::Read_Only::v, @$tail);
                }
            }    # q string
                . $action;

        }    # ACTION

        next RULE unless defined $action;

        my $code =
            "sub {\n" . "    package " . $package . ";\n" . $action . "\n}";

        if ($trace_actions) {
            print $trace_fh "Setting action for rule ",
                Parse::Marpa::brief_rule($rule), " to\n", $code, "\n";
        }

        my $closure;
        {
            my @warnings;
            local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
            $closure = eval $code;
            my $fatal_error = $@;
            if ($fatal_error or @warnings) {
                Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                    "compiling action",
                    "compiling action for "
                        . Parse::Marpa::brief_original_rule($rule),,
                    \$code
                );
            }
        }

        $rule->[Parse::Marpa::Internal::Rule::ACTION] = $code;
        $rule->[Parse::Marpa::Internal::Rule::CLOSURE] = $closure;

    }    # RULE

    my @lexers;
    $#lexers = $#$symbols;

    SYMBOL: for ( my $ix = 0; $ix <= $#lexers; $ix++ ) {

        my $symbol = $symbols->[$ix];
        my ( $name, $regex, $action, $symbol_prefix, $symbol_suffix ) = @{$symbol}[
            Parse::Marpa::Internal::Symbol::NAME,
            Parse::Marpa::Internal::Symbol::REGEX,
            Parse::Marpa::Internal::Symbol::ACTION,
            Parse::Marpa::Internal::Symbol::PREFIX,
            Parse::Marpa::Internal::Symbol::SUFFIX,
        ];

        if ( defined $regex ) {
            $lexers[$ix] = $regex;
            next SYMBOL;
        }

        my $prefix = $symbol_prefix // $default_prefix;
        $prefix = qr/$prefix/ if defined $prefix;
        my $suffix = $symbol_suffix // $default_suffix;
        $suffix = qr/$suffix/ if defined $suffix;

        given ($action) {
            when (undef) {;}    # do nothing
                                # Right now do nothing but find lex_q_quote
            when ("lex_q_quote") {
                $lexers[$ix] = [\&Parse::Marpa::Lex::lex_q_quote, $prefix, $suffix];
            }
            when ("lex_regex") {
                $lexers[$ix] = [\&Parse::Marpa::Lex::lex_regex, $prefix, $suffix];
            }
            default {
                my $code = q'
                        sub {
                            my $STRING = shift;
                            my $START = shift;
                     '
                    . "package " . $package . ";\n" . $action . "; return\n}";

                if ($trace_actions) {
                    print $trace_fh
                        "Setting action for terminal ", $name, " to\n", $code,
                        "\n";
                }

                my $closure;
                {
                    my @warnings;
                    local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
                    $closure = eval $code;
                    my $fatal_error = $@;
                    if ($fatal_error or @warnings) {
                        Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                            "compiling action",
                            "compiling action for $name",
                            \$code
                        );
                    }
                }

                $symbol->[ Parse::Marpa::Internal::Symbol::ACTION ] = $code;
                $lexers[$ix] = [$closure, $prefix, $suffix];

            }
        }

    }    # SYMBOL

    my @lexables_by_state;
    $#lexables_by_state = $#$SDFA;

    for my $state (@$SDFA) {
        my ( $id, $transition ) = @{$state}[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::TRANSITION,
        ];
        $lexables_by_state[$id] = [
            grep { $lexers[$_] }
                map {
                $symbol_hash->{$_}->[Parse::Marpa::Internal::Symbol::ID]
                }
                grep { $_ ne "" }
                keys %$transition
        ];
    }

    return ( \@lexers, \@lexables_by_state, );

}    # sub set_actions

sub compile_regexes {
    my $grammar = shift;
    my ( $symbols, $default_lex_prefix, $default_lex_suffix, ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX,
        Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX,
    ];

    SYMBOL: for my $symbol (@$symbols) {
        my $regex = $symbol->[Parse::Marpa::Internal::Symbol::REGEX];
        next SYMBOL unless defined $regex;
        if ( "" =~ $regex ) {
            my $name = $symbol->[Parse::Marpa::Internal::Symbol::NAME];
            croak( "Attempt to add nullable terminal: ", $name );
        }
        my $prefix = $symbol->[Parse::Marpa::Internal::Symbol::PREFIX]
            // $default_lex_prefix;
        my $suffix = $symbol->[Parse::Marpa::Internal::Symbol::SUFFIX]
            // $default_lex_suffix;
        my $compiled_regex = qr/
            \G
            (?<mArPa_prefix>$prefix)
            (?<mArPa_match>$regex)
            (?<mArPa_suffix>$suffix)
        /xms;
        $symbol->[Parse::Marpa::Internal::Symbol::REGEX] = $compiled_regex;
    }    # SYMBOL

}

sub set_priorities {
    my $grammar    = shift;
    my $priorities = [];
    my $problem    = 0;

    my ($trace_fh, $trace_priorities);
    if ($grammar->[ Parse::Marpa::Internal::Grammar::TRACING ]) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_priorities = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES ];
    }
    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    $#$priorities = $#$SDFA;

    for my $state (@$SDFA) {
        my $priority;
        my $priority_conflict = 0;
        my ( $id, $complete_rules_by_lhs ) = @{$state}[
            Parse::Marpa::Internal::SDFA::ID,
            Parse::Marpa::Internal::SDFA::COMPLETE_RULES,
        ];
        my @complete_rules;
        LHS: for my $lhs_id ( 0 .. $#$complete_rules_by_lhs ) {
            my $rules = $complete_rules_by_lhs->[$lhs_id];
            next LHS unless defined $rules;
            push( @complete_rules, @$rules );
        }
        COMPLETE_RULE: for my $complete_rule (@complete_rules) {
            my $rule_priority =
                $complete_rule->[Parse::Marpa::Internal::Rule::PRIORITY];
            given ($priority) {
                when (undef) { $priority = $rule_priority }
                when ( $rule_priority != $_ ) { $priority_conflict++; }
            }
        }
        if ($priority_conflict) {
            $problem++;
            carp( "Priority conflict in SDFA ", $id );
            COMPLETE_RULE: for my $complete_rule (@complete_rules) {
                my $rule_priority =
                    $complete_rule->[Parse::Marpa::Internal::Rule::PRIORITY];
                carp(
                    "SDFA ", $id, ": ",
                    Parse::Marpa::brief_rule($complete_rule),
                    "has priority ",
                    $rule_priority
                );
            }
        }
        $priorities->[$id] = $priority // 0;
        if ($trace_priorities) {
            say $trace_fh "Priority for state $id: ", $priorities->[$id];
        }
    }    # for each SDFA state
    if ($problem) {
        croak( "Marpa cannot continue: ", $problem, " priority conflicts" );
    }

    $priorities;

}    # sub set_priorities

sub eval_grammar {
    my $parse          = shift;
    my $grammar        = shift;

    local ($Data::Dumper::Terse)       = 1;
    my $package = $parse->[Parse::Marpa::Internal::Parse::PACKAGE] =
        sprintf( "Parse::Marpa::P_%x", $parse_number++ );

    my $preamble = $grammar->[Parse::Marpa::Internal::Grammar::PREAMBLE];
    my $default_action = $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION];
    my $default_null_value = $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE];

    if ( defined $preamble ) {
        my @warnings;
        local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
        eval( "package " . $package . ";\n" . $preamble );
        my $fatal_error = $@;
        if ($fatal_error or @warnings) {
            Parse::Marpa::Internal::die_on_problems($fatal_error, \@warnings,
                "evaluating preamble",
                "evaluating preamble",
                \$preamble
            );
        }
    }

    compile_regexes($grammar);
    set_null_values( $grammar, $package );
    @{$parse}[ LEXERS, LEXABLES_BY_STATE ] =
        set_actions( $grammar, $package );
    $parse->[PRIORITIES] = set_priorities($grammar);
    $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
        Parse::Marpa::Internal::Grammar::EVALED;

}

# Returns the new parse object or throws an exception
sub Parse::Marpa::Recce::new {
    my $class = shift;

    my $parse = [];
    my $ambiguous_lex;
    my $preamble;

    my $args = {@_};
    my $grammar = $args->{grammar};
    croak("No grammar specified") unless defined $grammar;
    delete $args->{grammar};

    my $grammar_class = ref $grammar;
    croak(
        "Don't recognize parse() grammar arg has wrong class: $grammar_class")
        unless $grammar_class eq "Parse::Marpa";

    Parse::Marpa::set($grammar, %{$args});
    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING ];

    # We always get the trace file handle, because we often need it to pass to
    # decompile, below.
    my $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::show_problems($grammar),
            "Attempt to parse grammar with fatal problems\n",
            "Marpa cannot proceed",
        );
    }

    if ( $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] ) {
        croak(
            "Attempt to parse grammar marked academic\n",
            "Marpa cannot proceed"
        );
    }

    # Finalize the value of volatile
    # undef means volatile (boolean true, or 1)
    $grammar->[ Parse::Marpa::Internal::Grammar::VOLATILE ] //= 1;

    # allow the user to use a grammar "in place"?
    STATE:
    while ( my $state = $grammar->[Parse::Marpa::Internal::Grammar::STATE] )
    {
        last STATE if $state eq Parse::Marpa::Internal::Grammar::EVALED;
        given ($state) {
            when (Parse::Marpa::Internal::Grammar::PERL_RULES) {
                my $compiled_grammar = Parse::Marpa::compile($grammar);
                $grammar = Parse::Marpa::decompile($compiled_grammar, $trace_fh);
            }
            when (Parse::Marpa::Internal::Grammar::SOURCE_RULES) {
                my $compiled_grammar = Parse::Marpa::compile($grammar);
                $grammar = Parse::Marpa::decompile($compiled_grammar, $trace_fh);
            }
            when (Parse::Marpa::Internal::Grammar::PRECOMPUTED) {
                my $compiled_grammar = Parse::Marpa::compile($grammar);
                $grammar = Parse::Marpa::decompile($compiled_grammar, $trace_fh);
            }
            when (Parse::Marpa::Internal::Grammar::COMPILED) {
                eval_grammar( $parse, $grammar );
            }
            when (Parse::Marpa::Internal::Grammar::IN_USE) {
                croak("Attempt to parse grammar already in use");
            }
            when (Parse::Marpa::Internal::Grammar::NEW) {
                croak("Attempt to parse grammar without rules");
            }
            default {
                croak(
                    "Attempt to parse grammar in inappropriate state\nAttempt to parse ",
                    $state
                );
            }
        }
    }    # while ne EVALED

    $grammar->[Parse::Marpa::Internal::Grammar::STATE] =
        Parse::Marpa::Internal::Grammar::IN_USE;

    my $earley_hash;
    my $earley_set;
    my $item;

    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];

    # Here I rely on an assumption about the numbering
    # of the SDFA states -- specifically, that state 0 contains the
    # start productions.
    my $SDFA0 = $SDFA->[0];
    my $key = pack( "JJ", $SDFA0 + 0, 0 );
    @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::PARENT,
        Parse::Marpa::Internal::Earley_item::TOKENS,
        Parse::Marpa::Internal::Earley_item::LINKS,
        Parse::Marpa::Internal::Earley_item::SET
        ]
        = ( $SDFA0, 0, [], [], 0 );
    push( @$earley_set, $item );
    $earley_hash->{$key} = $item;

    my $resetting_state =
        $SDFA0->[Parse::Marpa::Internal::SDFA::TRANSITION]->{""};
    if ( defined $resetting_state ) {
        $key = pack( "JJ", $resetting_state, 0 );
        undef $item;
        @{$item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT,
            Parse::Marpa::Internal::Earley_item::TOKENS,
            Parse::Marpa::Internal::Earley_item::LINKS,
            Parse::Marpa::Internal::Earley_item::SET
            ]
            = ( $resetting_state, 0, [], [], 0 );
        push( @$earley_set, $item );
        $earley_hash->{$key} = $item;
    }

    @{$parse}[
        DEFAULT_PARSE_SET, CURRENT_SET,       FURTHEST_EARLEME,
        EARLEY_HASHES,     GRAMMAR,           EARLEY_SETS,
        LAST_COMPLETED_SET,
        ]
        = (
        0, 0, 0, [$earley_hash],
        $grammar, [$earley_set],
        -1,
        );

    bless $parse, $class;
}

# Viewing methods, for debugging

sub Parse::Marpa::brief_earley_item {
    my $item = shift;
    my $ii   = shift;
    my ( $state, $parent, $set ) = @{$item}[
        Parse::Marpa::Internal::Earley_item::STATE,
        Parse::Marpa::Internal::Earley_item::PARENT,
        Parse::Marpa::Internal::Earley_item::SET
    ];
    my ( $id, $tag ) = @{$state}[
        Parse::Marpa::Internal::SDFA::ID,
        Parse::Marpa::Internal::SDFA::TAG
    ];
    my $text = ( $ii and defined $tag ) ? ( "St" . $tag ) : ( "S" . $id );
    $text .= '@' . $parent . '-' . $set;
}

sub show_token_choice {
    my $token = shift;
    my $ii    = shift;
    "[p="
        . Parse::Marpa::brief_earley_item( $token->[0], $ii ) . "; t="
        . $token->[1] . "]";
}

sub show_link_choice {
    my $link = shift;
    my $ii   = shift;
    "[p="
        . Parse::Marpa::brief_earley_item( $link->[0], $ii ) . "; c="
        . Parse::Marpa::brief_earley_item( $link->[1], $ii ) . "]";
}

sub Parse::Marpa::show_earley_item {
    my $item = shift;
    my $ii   = shift;
    my ($tokens,      $links,        $rules,     $rule_choice,
        $link_choice, $token_choice, $value,     $pointer,
        $lhs,         $predecessor,  $successor, $effect,
        )
        = @{$item}[
        Parse::Marpa::Internal::Earley_item::TOKENS,
        Parse::Marpa::Internal::Earley_item::LINKS,
        Parse::Marpa::Internal::Earley_item::RULES,
        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
        Parse::Marpa::Internal::Earley_item::VALUE,
        Parse::Marpa::Internal::Earley_item::POINTER,
        Parse::Marpa::Internal::Earley_item::LHS,
        Parse::Marpa::Internal::Earley_item::PREDECESSOR,
        Parse::Marpa::Internal::Earley_item::SUCCESSOR,
        Parse::Marpa::Internal::Earley_item::EFFECT,
        ];

    my $text = Parse::Marpa::brief_earley_item( $item, $ii );
    $text .= "  predecessor: " . Parse::Marpa::brief_earley_item($predecessor)
        if defined $predecessor;
    $text .= "  successor: " . Parse::Marpa::brief_earley_item($successor)
        if defined $successor;
    $text .= "  effect: " . Parse::Marpa::brief_earley_item($effect)
        if defined $effect;
    my @symbols;
    push( @symbols,
        "pointer: " . $pointer->[Parse::Marpa::Internal::Symbol::NAME] )
        if defined $pointer;
    push( @symbols, "lhs: " . $lhs->[Parse::Marpa::Internal::Symbol::NAME] )
        if defined $lhs;
    $text .= "\n  " . join( "; ", @symbols ) if @symbols;
    $text .= "\n  value: " . Parse::Marpa::show_value( $value, $ii )
        if defined $value;

    if ( defined $tokens and @$tokens ) {
        $text .= "\n  token choice " . $token_choice;
        for my $token (@$tokens) {
            $text .= " " . show_token_choice( $token, $ii );
        }
    }
    if ( defined $links and @$links ) {
        $text .= "\n  link choice " . $link_choice;
        for my $link (@$links) {
            $text .= " " . show_link_choice( $link, $ii );
        }
    }
    if ( defined $rules and @$rules ) {
        $text .= "\n  rule choice " . $rule_choice;
        for my $rule (@$rules) {
            $text .= " [ " . Parse::Marpa::brief_rule($rule) . " ]";
        }
    }
    $text;
}

sub Parse::Marpa::show_earley_set {
    my $earley_set = shift;
    my $ii         = shift;
    my $text       = "";
    for my $earley_item (@$earley_set) {
        $text .= Parse::Marpa::show_earley_item( $earley_item, $ii ) . "\n";
    }
    $text;
}

sub Parse::Marpa::show_earley_set_list {
    my $earley_set_list  = shift;
    my $ii               = shift;
    my $text             = "";
    my $earley_set_count = @$earley_set_list;
    LIST: for ( my $ix = 0; $ix < $earley_set_count; $ix++ ) {
        my $set = $earley_set_list->[$ix];
        next LIST unless defined $set;
        $text .= "Earley Set $ix\n"
            . Parse::Marpa::show_earley_set( $set, $ii );
    }
    $text;
}

sub Parse::Marpa::Recce::show_status {
    my $parse = shift;
    my $ii    = shift;
    my ( $current_set, $furthest_earleme, $earley_set_list ) =
        @{$parse}[ CURRENT_SET, FURTHEST_EARLEME, EARLEY_SETS ];
    my $text =
          "Current Earley Set: "
        . $current_set
        . "; Furthest: "
        . $furthest_earleme . "\n";
    $text .= Parse::Marpa::show_earley_set_list( $earley_set_list, $ii );
}

sub Parse::Marpa::Recce::clear_notations {
    my $parse = shift;
    my ($earley_set_list) = @{$parse}[EARLEY_SETS];
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
    my $parse = shift;
    my ($earley_set_list) = @{$parse}[EARLEY_SETS];
    for my $earley_set (@$earley_set_list) {
        for my $earley_item (@$earley_set) {
            $earley_item->[ Parse::Marpa::Internal::Earley_item::VALUE ] = undef;
        }
    }
}

# check class of parse?
sub Parse::Marpa::Recce::earleme {
    my $parse = shift;

    my $grammar = $parse->[ Parse::Marpa::Internal::Parse::GRAMMAR ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    # lexables not checked -- don't use prediction here
    # maybe add this as an option?
    my $lexables = Parse::Marpa::Internal::Parse::complete_set($parse);
    return Parse::Marpa::Internal::Parse::scan_set( $parse, @_ );
}

# Returns the position where the parse was exhausted,
# or -1 if the parse is not exhausted

# First arg is the current parse object
# Second arg is ref to string
sub Parse::Marpa::Recce::text {
    my $parse     = shift;
    my $input_ref = shift;
    my $length    = shift;
    croak("Parse::Marpa::Recce::text() third argument not yet implemented")
        if defined $length;

    croak("text argument to Parse::Marpa::Recce::text() must be string ref")
        unless ref $input_ref eq "SCALAR";

    my ( $grammar, $earley_sets, $current_set, 
        $lexers, )
        = @{$parse}[
        Parse::Marpa::Internal::Parse::GRAMMAR,
        Parse::Marpa::Internal::Parse::EARLEY_SETS,
        Parse::Marpa::Internal::Parse::CURRENT_SET,
        Parse::Marpa::Internal::Parse::LEXERS,
        ];

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    my $trace_lex_tries;
    my $trace_lex_matches;
    if ($tracing) {
         $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
         $trace_lex_tries = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ];
         $trace_lex_matches = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ];
    }

    my (
        $symbols, $ambiguous_lex
    ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::AMBIGUOUS_LEX,
    ];

    $length = length $$input_ref unless defined $length;

    POS: for ( my $pos = ( pos $$input_ref // 0 ); $pos < $length; $pos++ ) {
        my @alternatives;

        # NOTE: Often the number of the earley set, and the idea of
        # lexical position will correspond.  Be careful that Marpa
        # imposes no such requirement, however.

        my $lexables = complete_set($parse);

        if ( $trace_lex_tries and scalar @$lexables ) {
            my $string_to_match = substr( $$input_ref, $pos, 20 );
            $string_to_match
                =~ s/([\x00-\x1F\x7F-\xFF])/sprintf("{%#.2x}", ord($1))/ge;
            say $trace_fh "Match target at $pos: ",
                $string_to_match;
        }

        LEXABLE: for my $lexable (@$lexables) {
            my ($symbol_id) = @{$lexable}[Parse::Marpa::Internal::Symbol::ID];
            if ($trace_lex_tries) {
                print $trace_fh "Trying to match ",
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos\n";
            }

            my $lexer      = $lexers->[$symbol_id];
            my $lexer_type = ref $lexer;
            croak("Illegal type for lexer: undefined")
                unless defined $lexer_type;

            pos $$input_ref = $pos;

            if ( $lexer_type eq "Regexp" ) {
                if ( $$input_ref =~ /$lexer/g ) {
                    my $match = $+{mArPa_match};

                    # my $prefix = $+{mArPa_prefix};
                    # my $suffix = $+{mArPa_suffix};
                    # my $length = length(${^MATCH});
                    my $length = ( pos $$input_ref ) - $pos;
                    croak(
                        "Internal error, zero length token -- this is a Marpa bug"
                    ) unless $length;
                    push( @alternatives, [ $lexable, $match, $length ] );
                    if ($trace_lex_matches) {
                        print $trace_fh
                            "Matched regex for ",
                            $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                            " at $pos: ", $match, "\n";
                    }
                    last LEXABLE unless $ambiguous_lex;
                }    # if match

                next LEXABLE;

            }    # if defined regex

            # If it's a lexable and a regex was not defined, there must be a
            # closure
            croak("Illegal type for lexer: $lexer_type")
                unless $lexer_type eq "ARRAY";

            my ($lex_closure, $prefix, $suffix) = @$lexer;
            if (defined $prefix) {
                $$input_ref =~ /\G$prefix/g;
            }

            my ( $match, $length );
            {
                my @warnings;
                local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };
                eval { ($match, $length) = $lex_closure->($input_ref, $pos); };
                my $fatal_error = $@;
                if ($fatal_error or @warnings) {
                    Parse::Marpa::Internal::die_on_problems(
                        $fatal_error, \@warnings,
                        "user supplied lexer",
                        "user supplied lexer for "
                            . $lexable->[Parse::Marpa::Internal::Symbol::NAME]
                            .  " at $pos",
                        \($lexable->[Parse::Marpa::Internal::Symbol::ACTION])
                    );
                }
            }

            next LEXABLE if not defined $match;

            $length //= length $match;

            push( @alternatives, [ $lexable, $match, $length ] );
            if ($trace_lex_matches) {
                print $trace_fh
                    "Matched Closure for ",
                    $lexable->[Parse::Marpa::Internal::Symbol::NAME],
                    " at $pos: ", $match, "\n";
            }

            last LEXABLE unless $ambiguous_lex;

        }    # LEXABLE

        my $active = scan_set( $parse, @alternatives );

        return $pos unless $active;

    }    # POS

    return -1;

}    # sub text

sub Parse::Marpa::Recce::end_input {
    my $parse = shift;

    my (
        $grammar,
        $current_set,
        $last_completed_set,
        $furthest_earleme,
    ) = @{$parse}[
        Parse::Marpa::Internal::Parse::GRAMMAR,
        Parse::Marpa::Internal::Parse::CURRENT_SET,
        Parse::Marpa::Internal::Parse::LAST_COMPLETED_SET,
        Parse::Marpa::Internal::Parse::FURTHEST_EARLEME,
    ];
    local ($Parse::Marpa::Internal::This::grammar) = $grammar;

    return if $last_completed_set >= $furthest_earleme;

    EARLEY_SET: while ($current_set <= $furthest_earleme) {
        Parse::Marpa::Internal::Parse::complete_set($parse);
        $current_set++;
        $parse->[ Parse::Marpa::Internal::Parse::CURRENT_SET ] = $current_set;
    }
}

=begin Apolegetic:

It's bad style, but this routine is in a tight loop and for efficiency
I pull the token alternatives out of @_ one by one as I go in the code,
rather than at the beginning of the method.

The remaining arguments should be a list of token alternatives, as
array references.  The array for each alternative is (token, value,
length), where token is a symbol reference, value can anything
meaningful to the user, and length is the length of this token in
earlemes.

=end Apolegetic:

=cut

# Given a parse object and a list of alternative tokens starting at
# the current earleme, compute the Earley set for that earleme
sub scan_set {
    my $parse = shift;

    my ( $earley_set_list, $earley_hash_list, $grammar, $current_set,
        $furthest_earleme, $exhausted, )
        = @{$parse}[
        EARLEY_SETS,      EARLEY_HASHES, GRAMMAR, CURRENT_SET,
        FURTHEST_EARLEME, EXHAUSTED
        ];
    croak("Attempt to scan tokens on an exhausted parse") if $exhausted;
    my $SDFA = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];

    my $earley_set = $earley_set_list->[$current_set];

    if ( not defined $earley_set ) {
        $earley_set_list->[$current_set] = [];
        if ( $current_set >= $furthest_earleme ) {
            $parse->[Parse::Marpa::Internal::Parse::EXHAUSTED] = $exhausted =
                1;
        }
        else {
            $parse->[CURRENT_SET]++;
        }
        return !$exhausted;
    }

    EARLEY_ITEM: for ( my $ix = 0; $ix < @$earley_set; $ix++ ) {

        my $earley_item = $earley_set->[$ix];
        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];

        # I allow ambigious tokenization.
        # Loop through the alternative tokens.
        ALTERNATIVE: for my $alternative (@_) {
            my ( $token, $value, $length ) = @$alternative;

            if ( $length <= 0 ) {
                croak(    "Token "
                        . $token->[Parse::Marpa::Internal::Symbol::NAME]
                        . " with bad length "
                        . $length );
            }

            # Make sure it's an allowed terminal symbol.
            # TODO: Must remember to be sure that
            # nulling symbols are never terminals
            unless ( $token->[Parse::Marpa::Internal::Symbol::TERMINAL] ) {
                my $name = $token->[Parse::Marpa::Internal::Symbol::NAME];
                croak(    "Non-terminal "
                        . ( defined $name ? "$name " : "" )
                        . "supplied as token" );
            }

            # compute goto(kernel_state, token_name)
            my $kernel_state =
                $SDFA->[ $state->[Parse::Marpa::Internal::SDFA::ID] ]
                ->[Parse::Marpa::Internal::SDFA::TRANSITION]
                ->{ $token->[Parse::Marpa::Internal::Symbol::NAME] };
            next ALTERNATIVE unless $kernel_state;

            # Create the kernel item and its link.
            my $target_ix = $current_set + $length;
            my $target_earley_hash =
                ( $earley_hash_list->[$target_ix] ||= {} );
            my $target_earley_set = ( $earley_set_list->[$target_ix] ||= [] );
            if ( $target_ix > $furthest_earleme ) {
                $parse->[Parse::Marpa::Internal::Parse::FURTHEST_EARLEME] =
                    $furthest_earleme = $target_ix;
            }
            my $key = pack( "JJ", $kernel_state, $parent );
            my $target_earley_item = $target_earley_hash->{$key};
            unless ( defined $target_earley_item ) {
                @{$target_earley_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKENS,
                    Parse::Marpa::Internal::Earley_item::SET
                    ]
                    = ( $kernel_state, $parent, 0, [], 0, [], $target_ix );
                $target_earley_hash->{$key} = $target_earley_item;
                push( @$target_earley_set, $target_earley_item );
            }
            push(
                @{  $target_earley_item
                        ->[Parse::Marpa::Internal::Earley_item::TOKENS]
                    },
                [ $earley_item, $value ]
            );

            my $resetting_state =
                $kernel_state->[Parse::Marpa::Internal::SDFA::TRANSITION]
                ->{""};
            next ALTERNATIVE unless defined $resetting_state;
            $key = pack( "JJ", $resetting_state, $target_ix );
            unless ( exists $target_earley_hash->{$key} ) {
                my $new_earley_item;
                @{$new_earley_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT,
                    Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                    Parse::Marpa::Internal::Earley_item::LINKS,
                    Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                    Parse::Marpa::Internal::Earley_item::TOKENS,
                    Parse::Marpa::Internal::Earley_item::SET
                    ]
                    = ( $resetting_state, $target_ix, 0, [], 0, [],
                    $target_ix );
                $target_earley_hash->{$key} = $new_earley_item;
                push( @$target_earley_set, $new_earley_item );
            }

        }    # ALTERNATIVE

    }    # EARLEY_ITEM

    $parse->[CURRENT_SET]++;

    return 1;

}    # sub scan_set

sub complete_set {
    my $parse = shift;

    my ($earley_set_list,   $earley_hash_list,  $grammar,
        $current_set,       $furthest_earleme,  $exhausted,
        $lexables_by_state, $priorities,
        )
        = @{$parse}[
        EARLEY_SETS,       EARLEY_HASHES,
        GRAMMAR,           CURRENT_SET,
        FURTHEST_EARLEME,  EXHAUSTED,
        LEXABLES_BY_STATE,
        PRIORITIES,
        ];
    croak("Attempt to complete another earley set in an exhausted parse")
        if $exhausted;

    my $earley_set  = $earley_set_list->[$current_set];
    my $earley_hash = $earley_hash_list->[$current_set];

    $earley_set ||= [];

    my ( $SDFA, $symbols, $tracing ) = @{$grammar}[
        Parse::Marpa::Internal::Grammar::SDFA,
        Parse::Marpa::Internal::Grammar::SYMBOLS,
        Parse::Marpa::Internal::Grammar::TRACING,
    ];

    my ($trace_fh, $trace_completions);
    if ($tracing) {
        $trace_fh = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE ];
        $trace_completions 
            = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS ];
    }

    my $lexable_seen = [];
    $#$lexable_seen = $#$symbols;

    EARLEY_ITEM: for ( my $ix = 0; $ix < @$earley_set; $ix++ ) {

        my $earley_item = $earley_set->[$ix];
        my ( $state, $parent ) = @{$earley_item}[
            Parse::Marpa::Internal::Earley_item::STATE,
            Parse::Marpa::Internal::Earley_item::PARENT
        ];
        my $state_id = $state->[Parse::Marpa::Internal::SDFA::ID];

        for my $lexable ( @{ $lexables_by_state->[$state_id] } ) {
            $lexable_seen->[$lexable] = 1;
        }

        next EARLEY_ITEM if $current_set == $parent;

        COMPLETE_RULE:
        for my $complete_symbol_name (
            @{ $state->[Parse::Marpa::Internal::SDFA::COMPLETE_LHS] } )
        {
            PARENT_ITEM:
            for my $parent_item ( @{ $earley_set_list->[$parent] } ) {
                my ( $parent_state, $grandparent ) = @{$parent_item}[
                    Parse::Marpa::Internal::Earley_item::STATE,
                    Parse::Marpa::Internal::Earley_item::PARENT
                ];
                my $kernel_state =
                    $SDFA->[ $parent_state->[Parse::Marpa::Internal::SDFA::ID]
                    ]->[Parse::Marpa::Internal::SDFA::TRANSITION]
                    ->{$complete_symbol_name};
                next PARENT_ITEM unless defined $kernel_state;

                my $key = pack( "JJ", $kernel_state, $grandparent );
                my $target_earley_item = $earley_hash->{$key};
                unless ( defined $target_earley_item ) {
                    @{$target_earley_item}[
                        Parse::Marpa::Internal::Earley_item::STATE,
                        Parse::Marpa::Internal::Earley_item::PARENT,
                        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                        Parse::Marpa::Internal::Earley_item::LINKS,
                        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                        Parse::Marpa::Internal::Earley_item::TOKENS,
                        Parse::Marpa::Internal::Earley_item::SET
                        ]
                        = (
                        $kernel_state, $grandparent, 0, [], 0, [],
                        $current_set
                        );
                    $earley_hash->{$key} = $target_earley_item;
                    push( @$earley_set, $target_earley_item );
                }
                push(
                    @{  $target_earley_item
                            ->[Parse::Marpa::Internal::Earley_item::LINKS]
                        },
                    [ $parent_item, $earley_item ]
                );

                my $resetting_state =
                    $kernel_state->[Parse::Marpa::Internal::SDFA::TRANSITION]
                    ->{""};
                next PARENT_ITEM unless defined $resetting_state;
                $key = pack( "JJ", $resetting_state, $current_set );
                unless ( defined $earley_hash->{$key} ) {
                    my $new_earley_item;
                    @{$new_earley_item}[
                        Parse::Marpa::Internal::Earley_item::STATE,
                        Parse::Marpa::Internal::Earley_item::PARENT,
                        Parse::Marpa::Internal::Earley_item::LINK_CHOICE,
                        Parse::Marpa::Internal::Earley_item::LINKS,
                        Parse::Marpa::Internal::Earley_item::TOKEN_CHOICE,
                        Parse::Marpa::Internal::Earley_item::TOKENS,
                        Parse::Marpa::Internal::Earley_item::SET
                        ]
                        = (
                        $resetting_state, $current_set, 0, [], 0, [],
                        $current_set
                        );
                    $earley_hash->{$key} = $new_earley_item;
                    push( @$earley_set, $new_earley_item );
                }

            }    # PARENT_ITEM

        }    # COMPLETE_RULE

    }    # EARLEY_ITEM

    EARLEY_ITEM: for my $earley_item (@$earley_set) {
        my $links =
            $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS];
        my @sorted_links =
            map  { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map {
            [   $_,
                $priorities->[
                    $_->[1]->[Parse::Marpa::Internal::Earley_item::STATE]
                    ->[Parse::Marpa::Internal::SDFA::ID]
                ]
            ]
            } @$links;
        $earley_item->[Parse::Marpa::Internal::Earley_item::LINKS] =
            \@sorted_links;
    }

    # TODO: Prove that the completion links are UNIQUE

    # Free memory for the hash
    $earley_hash_list->[$current_set] = undef;

    $parse->[Parse::Marpa::Internal::Parse::DEFAULT_PARSE_SET] = $current_set;
    $parse->[Parse::Marpa::Internal::Parse::LAST_COMPLETED_SET] = $current_set;

    if ($trace_completions) {
        print $trace_fh Parse::Marpa::show_earley_set($earley_set);
    }

    # Dream up some efficiency hack here.  Memoize sorted lexables by state?
    my $lexables = [
        sort {
            $a->[Parse::Marpa::Internal::Symbol::PRIORITY]
                <=> $b->[Parse::Marpa::Internal::Symbol::PRIORITY]
            }
            map { $symbols->[$_] }
            grep { $lexable_seen->[$_] } ( 0 .. $#$symbols )
    ];
    return $lexables;

}    # sub complete_set

sub Parse::Marpa::Recce::show {
    my $parse = shift;
    my $text  = "";

    croak("No parse supplied") unless defined $parse;

    my ( $start_item, $current_parse_set ) = @{$parse}[
        Parse::Marpa::Internal::Parse::START_ITEM,
        Parse::Marpa::Internal::Parse::CURRENT_PARSE_SET,
    ];

    local ($Data::Dumper::Terse)       = 1;

    my $value = $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    croak("Parse not evaluated") unless defined $value;

    my ( $rules, $rule_choice ) = @{$start_item}[
        Parse::Marpa::Internal::Earley_item::RULES,
        Parse::Marpa::Internal::Earley_item::RULE_CHOICE,
    ];

    $text .= Parse::Marpa::show_derivation($start_item);

}

sub Parse::Marpa::show_derivation {
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

# returns 1 if it starts OK, undef otherwise
sub Parse::Marpa::Recce::initial {
    my $parse         = shift;
    my $parse_set_arg = shift;

    my $parse_class = ref $parse;
    my $right_class = "Parse::Marpa::Recce";
    croak(
        "Don't parse argument is class: $parse_class; should be: $right_class"
    ) unless $parse_class eq $right_class;

    my ($grammar,                 $earley_sets,
        )
        = @{$parse}[
        Parse::Marpa::Internal::Parse::GRAMMAR,
        Parse::Marpa::Internal::Parse::EARLEY_SETS,
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
         Parse::Marpa::Recce::end_input($parse);
    }
    my $default_parse_set = $parse->[ Parse::Marpa::Internal::Parse::DEFAULT_PARSE_SET ];

    $parse->[ Parse::Marpa::Internal::Parse::PARSE_COUNT ] = 0;
    Parse::Marpa::Recce::clear_notations($parse);

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

    @{$parse}[
        Parse::Marpa::Internal::Parse::START_ITEM,
        Parse::Marpa::Internal::Parse::CURRENT_PARSE_SET,
        ]
        = ( $start_item, $current_parse_set );

     finish_evaluation($parse);

     1;
}

sub finish_evaluation {
    my $parse = shift;

    # mark start items with LHS?
    my $start_item = $parse->[ Parse::Marpa::Internal::Parse::START_ITEM ];
    my $grammar = $parse->[ Parse::Marpa::Internal::Parse::GRAMMAR ];

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

sub Parse::Marpa::Recce::find_complete_rule {
    my $parse         = shift;
    my $start_earleme = shift;
    my $symbol        = shift;
    my $last_earleme  = shift;

    my ( $default_parse_set, $earley_sets, ) = @{$parse}[
        Parse::Marpa::Internal::Parse::DEFAULT_PARSE_SET,
        Parse::Marpa::Internal::Parse::EARLEY_SETS,
    ];

    # Set up the defaults for undefined arguments
    $start_earleme //= 0;
    $last_earleme  //= $default_parse_set;
    $last_earleme = $default_parse_set if $last_earleme > $default_parse_set;

    EARLEME:
    for (
        my $earleme = $last_earleme;
        $earleme >= $start_earleme;
        $earleme--
        )
    {
        my $earley_set = $earley_sets->[$earleme];

        ITEM: for my $earley_item (@$earley_set) {
            my ( $state, $parent ) = @{$earley_item}[
                Parse::Marpa::Internal::Earley_item::STATE,
                Parse::Marpa::Internal::Earley_item::PARENT,
            ];
            next ITEM unless $parent == $start_earleme;
            if ( defined $symbol ) {
                my $complete_rules =
                    $state->[Parse::Marpa::Internal::SDFA::COMPLETE_RULES]
                    ->{$symbol};
                next ITEM unless $complete_rules;
            }
            my $complete_lhs =
                $state->[Parse::Marpa::Internal::SDFA::COMPLETE_LHS];
            next ITEM unless scalar @$complete_lhs;
            return ( $earleme, $complete_lhs );
        }    # ITEM
    }    # EARLEME
    return;
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

    local ($Parse::Marpa::Read_Only::v) = [];    # to store values in

    my @work_entries;

    CHILD:
    for ( my $child_number = $#$rhs; $child_number >= 0; $child_number-- ) {

        my $child_symbol = $rhs->[$child_number];
        my $nulling =
            $child_symbol->[Parse::Marpa::Internal::Symbol::NULLING];

        if ($nulling) {
            my $null_value
                = $child_symbol->[Parse::Marpa::Internal::Symbol::NULL_VALUE];
            $Parse::Marpa::Read_Only::v->[$child_number] = $null_value;

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
            $Parse::Marpa::Read_Only::v->[$child_number] = $$previous_value;
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
            $Parse::Marpa::Read_Only::v->[$child_number] = $value;
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
        my $value = $Parse::Marpa::Read_Only::v->[$rhs_index] =
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
        $result = eval { $closure->() };
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

sub Parse::Marpa::Recce::value {
    my $parse = shift;

    my $start_item = $parse->[Parse::Marpa::Internal::Parse::START_ITEM];
    return unless defined $start_item;
    my $value_ref = $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    croak("No value defined") unless defined $value_ref;
    return $value_ref;
}

sub Parse::Marpa::Recce::next {
    my $parse = shift;

    croak("No parse supplied") unless defined $parse;
    my $parse_class = ref $parse;
    my $right_class = "Parse::Marpa::Recce";
    croak(
        "Don't parse argument is class: $parse_class; should be: $right_class"
    ) unless $parse_class eq $right_class;

    my ( $grammar, $start_item, $current_parse_set, )
        = @{$parse}[
        Parse::Marpa::Internal::Parse::GRAMMAR,
        Parse::Marpa::Internal::Parse::START_ITEM,
        Parse::Marpa::Internal::Parse::CURRENT_PARSE_SET,
        ];

    # TODO: Is this check enough be sure that this is an evaluated parse?
    croak("Parse not initialized: no start item") unless defined $start_item;
    my $start_value =
        $start_item->[Parse::Marpa::Internal::Earley_item::VALUE];
    croak("Parse not initialized: no start value")
        unless defined $start_value;

    my $max_parses = $grammar->[ Parse::Marpa::Internal::Grammar::MAX_PARSES ];
    if ($max_parses > 0 && $parse->[ Parse::Marpa::Internal::Parse::PARSE_COUNT ]++ > $max_parses) {
        croak("Maximum parse count ($max_parses) exceeded");
    }

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
    clear_values($parse) if $volatile;

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
        finish_evaluation( $parse );

        # Rejected evaluations are not yet implemented.
        # Therefore this evaluation pass succeeded.
        return 1;

    }    # EVALUATION

    return;

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

=head2 The Easy Way

It's possible to specify the grammar and the text to be parsed all in one step

    use Parse::Marpa;
    my $value = Parse::Marpa::marpa(\$grammar, \$text_to_parse);

The syntax for C<$grammar> can be found in the document for the
L<Marpa Demonstration Language|Parse::Marpa::LANGUAGE.pod>.
You can even include options if you make a hash ref the third argument.

    my $value = Parse::Marpa::marpa(
        \$grammar,
        \$text_to_parse
        {
            warnings => 1,
        }
    );

To get all the values of an ambiguous parse, invoke C<Parse::Marpa::marpa()> in
list context.

    my @values = Parse::Marpa::marpa(\$ambiguous_grammar, \$text_to_parse);

=head2 Step by Step

First, set things up ...

    use Parse::Marpa;

    my @tests = split(/\n/, <<'EO_TESTS');
    time  / 25 ; # / ; die "this dies!";
    localtime  / 25 ; # / ; die "this dies!";
    EO_TESTS

then create a grammar object, ...

    my $g = new Parse::Marpa(
        warnings => 1,
        code_lines => -1,
    );

and set the grammar.

    my $mock_perl_grammar; { local($RS) = undef; $mock_perl_grammar = <DATA> };
    $g->set( source => \$mock_perl_grammar);

Next, as many times as you like, ...

    TEST: while (my $test = pop @tests) {

create a parse object, ...

        my $parse = new Parse::Marpa::Recce($g);

pass text to the recognizer, ...

        $parse->text(\$test);

evaluate the initial parse, ...

        $parse->initial();
        my @parses;
        push(@parses, $parse->value);

... and get others, if there are any.

        while ($parse->next) {
            push(@parses, $parse->value);
        }

You're now ready to announce your results and continue the loop.

        say "I've got ", scalar @parses, " parses:";
        for (my $i = 0; $i < @parses; $i++) {
            say "Parse $i: ", ${$parses[$i]};
        }
    }

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

=head1 THE STATUS OF THIS MODULE

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

=head1 READING THESE DOCUMENTS

L<Parse::Marpa::CONCEPTS> should be read before
using Marpa, in fact probably before your first careful reading of this document.
The "concepts" in it are all practical
-- the theoretical discussions went
into L<Parse::Marpa::ALGORITHM>.
Even experts in Earley parsing will want to skim L<Parse::Marpa::CONCEPTS>
because,
as one example,
the availability of ambiguous lexing has unusual implications for term I<token>.

L<Parse::Marpa::LANGUAGE> documents what is currently
Marpa's only high-level interface.
Of Marpa's current documents,
it is the most tutorial in approach.

=head1 THE EASY WAY

=over 4

=item Parse::Marpa::marpa(I<grammar>, I<text_to_parse>, I<option_hash>);

The C<marpa()> method takes three arguments:
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
L<Marpa Demonstration Language|Parse::Marpa::LANGUAGE>.

=back

=head1 METHODS FOR FINER CONTROL

=over 4

=item new Parse::Marpa(I<option> => I<value>, [I<option> => I<value>, ...])

C<Parse::Marpa::Recce::new()> takes as its arguments a series of I<option>, I<value> pairs which
are treated as a hash.  It returns a new grammar object or throws an exception.
For valid options see the L<options section|/"Options">.

=item new Parse::Marpa::Recce(I<option> => I<value>, [I<option> => I<value>, ...])

C<Parse::Marpa::Recce::new()> takes as its arguments a series of I<option>, I<value> pairs which
are treated as a hash.  It returns a new parse object or throws an exception.
The C<grammar> option must be specified,
and its value must be a grammar object with rules defined in it.
For valid options see the L<options section|/"Options">.

=item Parse::Marpa::Recce::text(I<parse>, I<text_to_parse>)

Extends the parse in the 
I<parse> object using the input I<text_to_parse>, a B<reference> to a string.
Returns -1 if the parse is still active after the I<text_to_parse>
has been processed.  Otherwise the offset of the character where the parse was exhausted
is returned.
Failures, other than exhausted parses,
are thrown as exceptions.

The text is parsed using the one-earleme-per-character model.
Terminals are recognized using the lexers that were specified in the source file
or with the raw interface.

The character offset where the parse was exhausted
is reported in characters from
the start of C<text_to_parse>.
The first character is at offset zero.
This means that a zero return from C<text()> indicates
that the parse was exhausted at the first character.

A parse is "exhausted" at a point in the input
where a successful parse becomes impossible.
In most cases,
an exhausted parse is a failed parse.

=item Parse::Marpa::Recce::earleme(I<parse>, I<token_list>)

Extends the parse one earleme using as the input at that earleme, I<token_list>,
a reference to a list of token alternatives.
Each token alternative is a reference to a three element array.
The first element is a "cookie" for the token's symbol,
as returned by the C<Parse::Marpa::get_symbol()> method.
The second element is the token's value in the parse.
The third is the token's length in earlemes.

Returns 1 on success.
Returns 0 if the parse was exhausted at that earleme.
Throws an exception on other failures.

This is the low-level token input method, and allows maximum
control over the context and form of tokens.
No model of the relationship between the input and the earlemes is assumed,
and the user is free to invent her own.

=item Parse::Marpa::get_symbol(I<grammar>, I<symbol_name>)

Given a symbol's raw interface name, returns the symbol's "cookie".
Returns undefined if a symbol with that name doesn't exist.

The primary use of symbol cookies is with C<Parse::Marpa::Recce::earleme()>.
To get the cookie for a symbol using a high-level interface symbol name,
see the documentation for the individual high level interface.

=item Parse::Marpa::Recce::initial(I<parse>, I<parse_end>)

Performs the recognition phase of a parse,
and initializes the iteration through its values.
On successful recognition of a parse, C<initial()> returns a value of 1.
The user may then get value of the parse with C<Parse::Marpa::Recce::value()>, 
and may iterate through any other parses with C<Parse::Marpa::Recce::next()>.

C<initial()> returns undefined if it fails to recognize a parse.
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
The C<Parse::Marpa::Recce::find_complete_rule()> method,
documented in L<the diagnostics document|Parse::Marpa::DIAGNOSTIC>,
is a prototype of the methods that will be needed in online mode.

=item Parse::Marpa::Recce::next(I<parse>)

Takes a parse object as its only argument,
and performs the next iteration through its values.
The iteration must have been initialized with
C<Parse::Marpa::Recce::initial()>.
Returns 1 if there was a next iteration.
Returns undefined when there are no more iterations.
Other failures are exceptions.

Parses are iterated from rightmost to leftmost, but their order
may be manipulated by assigning priorities to the rules and
terminals.

=item Parse::Marpa::Recce::value(I<parse>)

Takes a parse object, which has been set up with
C<Parse::Marpa::Recce::initial()>
and may have been iterated with
C<Parse::Marpa::Recce::next()>.
Returns a reference to its current value.
Failures are thrown as exceptions.

Defaults, nulling rules, and non-existent optional items
all have as their value a Perl 5 undefined.
These undefineds count as "node values"
and C<value()> returns them as a reference to an undefined.

In unusual cases,
(probably be the result of advanced wizardry gone wrong),
Marpa will not find a node value and
the return value will be undefined instead of a pointer to undefined.
This is considered a Marpa "no node value".
Returns of "no node value" should not occur
if you are in offline mode and 
use the default end parse location in your call to the C<initial()> method.

=back

=head1 LESS USED METHODS

The methods in this section explicitly run processing phases 
which Marpa typically performs indirectly.
For example, when C<Parse::Marpa::Recce::new()> is asked to create a new parse object
from a grammar which has not been through the precomputation phase,
that grammar is automatically precomputed
and deep copied.

The most important use of these methods is with diagnostics.
A user may want to trace Marpa's behavior during, or examine
a Marpa object immediately after, a particular processing phase.
In such cases, it can be helpful or even necessary to run the phase explicitly.

=over 4

=item Parse::Marpa::compile(I<grammar>) or $grammar->compile()

The C<compile> method takes as its single argument a grammar object, and "compiles" it,
that is, writes it out as a string, using L<Data::Dumper>.
It returns a reference to the compiled
grammar, or throws an exception.

=item Parse::Marpa::decompile(I<compiled_grammar>, [I<trace_file_handle>])

The C<decompile> static method takes a reference to a compiled grammar as its first
argument.
The second, optional, argument is a file handle.  It is used both to override the
compiled grammar's trace file handle, and for any trace messages produced by
C<decompile()> itself.
C<decompile()> returns the decompiled grammar object unless it throws an
exception.

If the trace file handle argument is omitted, it defaults to STDERR
and the new grammar's trace file handle reverts to the default for a new
grammar, which is also STDERR.
The trace file handle argument is needed because in the course of compilation,
the grammar's original trace file handle may have been lost.
For example, a compiled grammar can be written to a file and emailed.
Marpa cannot rely on finding the original trace file handle available and open
when the compiled grammar is decompiled.

Marpa compiles and decompiles a grammar as part of its deep copy processing phase.
Internally, the deep copy processing phase saves the trace file handle of the original grammar
to a temporary, then
restores it using the trace file handle argument of C<decompile()>.

=item Parse::Marpa::precompute(I<grammar>) or $grammar->precompute()

Takes as its only argument a grammar object and
performs the precomputation phase on it.  It returns the grammar
object or throws an exception.

=back

=head1 DIAGNOSTIC METHODS

L<The separate document on diagnostics|Parse::Marpa::DIAGNOSTICS> deals
with methods used primarily to debug grammars and parses.

=head1 OPTIONS

This section documents
the options recognized by the
C<Parse::Marpa::new()>,
C<Parse::Marpa::Recce::new()>,
and C<Parse::Marpa::set()> methods.
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
L<the separate document on diagnostics|Parse::Marpa::DIAGNOSTICS>.

=over 4

=item grammar

Takes as its value a grammar object.
Only valid as an option to
C<Parse::Marpa::Recce::new()>,
where it's required.

=item source

This takes as its value a B<reference> to a string containing a description of
the grammar in the L<Marpa Demonstartion Language|Parse::Marpa::LANGUAGE>.
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
C<Parse::Marpa::Recce::new()>,
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
L<the CONCEPTS document|Parse::Marpa::CONCEPTS>.

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
The method C<Parse::Marpa::Recce::find_complete_rule()>,
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
see L<Parse::Marpa::CONCEPTS>.

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
    Parse::Marpa::Recce

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

=head1 AUTHOR

Jeffrey Kegler

=head1 DEPENDENCIES

Requires Perl 5.10.
Users who want or need the maturity and/or stability of Perl 5.8 or earlier
are probably also best off with more mature and stable alternatives to Marpa.

=head1 LIMITATIONS

=head2 Speed

Speed seems very good for an Earley's implementation.
In fact, the current bottlenecks seem not to be in the Marpa parse engine, but
in the lexing, and in the design of the Marpa Demonstration Language.

=head3 Ambiguous Lexing and Speed

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

=head3 The Marpa Demonstration Language and Speed

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

=head2 More Generally, about Parsers and Speed

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
(see the L<internals document|Parse::Marpa::INTERNALS>),
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
L<Aycock and Horspool 2002|Parse::Marpa::BIBLIOGRAPHY/"Aycock and Horspool 2002">.
I've made significant changes to it,
which are documented separately (L<Parse::Marpa::ALGORITHM>).
Aycock and Horspool, for their part,
built on the
L<algorithm discovered by Jay Earley|Parse::Marpa::BIBLIOGRAPHY/"Earley 1970">.

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
