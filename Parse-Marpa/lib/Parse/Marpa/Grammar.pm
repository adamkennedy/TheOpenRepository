use 5.010_000;

use warnings;
no warnings "recursion";
use strict;
use integer;

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
use constant OPAQUE             => 20; # default for opacity
use constant PROBLEMS           => 21; # fatal problems
use constant PREAMBLE           => 22; # default preamble
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
use constant PHASE                    => 43; # the grammar's phase
use constant INTERFACE                => 44; # the grammar's interface

package Parse::Marpa::Internal::Interface;

# values for grammar interfaces
use constant RAW => 0;
use constant MDL => 1;

sub description {
  my $interface = shift;
  given($interface) {
      when (RAW) { return "raw interface" }
      when (MDL) { return "Marpa Description Language interface" }
      default { "unknown interface" }
  }
};

package Parse::Marpa::Internal::Phase;

# values for grammar phases
use constant NEW          => 0;
use constant RULES        => 1;
use constant PRECOMPUTED  => 2;
use constant COMPILED     => 3;
use constant EVALED       => 4;
use constant IN_USE       => 5;

sub description {
  my $phase = shift;
  given($phase) {
      when (NEW) { return "grammar without rules" }
      when (RULES) { return "grammar with rules entered" }
      when (PRECOMPUTED) { return "precomputed grammar" }
      when (COMPILED) { return "compiled grammar" }
      when (EVALED) { return "evaled grammar" }
      when (IN_USE) { return "in use grammar" }
      default { "unknown phase" }
  }
};

package Parse::Marpa::Internal::Grammar;

use Scalar::Util qw(weaken);
use Data::Dumper;
use Carp;

sub Parse::Marpa::Internal::die_on_problems {
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

sub Parse::Marpa::Internal::Grammar::raw_grammar_eval {
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

     Parse::Marpa::Internal::Grammar::add_user_rules($grammar, $new_rules);
     Parse::Marpa::Internal::Grammar::add_user_terminals($grammar, $new_terminals);

     $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
         Parse::Marpa::Internal::Phase::RULES;
     $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE] = 
         Parse::Marpa::Internal::Interface::RAW;

}

package Parse::Marpa::Internal::Grammar;

sub Parse::Marpa::Grammar::new {
    my $class = shift;
    my ($args) = @_;

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
    $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE] = undef;
    $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] = 1;
    $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] = 30;
    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::NEW;
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS]      = [];
    $grammar->[Parse::Marpa::Internal::Grammar::SYMBOL_HASH]  = {};
    $grammar->[Parse::Marpa::Internal::Grammar::RULES]        = [];
    $grammar->[Parse::Marpa::Internal::Grammar::RULE_HASH]    = {};
    $grammar->[Parse::Marpa::Internal::Grammar::SDFA_BY_NAME] = {};
    $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES ] = -1;
    $grammar->[Parse::Marpa::Internal::Grammar::ONLINE ] = 0;

    $grammar->set($args);
}

sub Parse::Marpa::show_source_grammar_status {
    my $status = $Parse::Marpa::Internal::compiled_source_grammar ?  "Compiled" : "Raw";
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

# Build a grammar from an MDL description.
# First arg is the grammar being built.
# Second arg is ref to string containing the MDL description.
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

    # my $grammar_version = $source_grammar->[ Parse::Marpa::Internal::Grammar::VERSION ];
    # no integer;
    # if ($Parse::Marpa::VERSION != $grammar_version) {
        # croak("Version mismatch between Marpa ($Parse::Marpa::VERSION) and its source grammar ($grammar_version)");
    # }
    # use integer;

    $source_options //= {};

    my $recce = new Parse::Marpa::Recognizer(
        {
	    compiled_grammar => $Parse::Marpa::Internal::compiled_source_grammar,
	    trace_file_handle => $trace_fh,
	    %{$source_options}
	}
    );

    my $failed_at_earleme = $recce->text($source);
    if ($failed_at_earleme >= 0) {
        die_with_parse_failure($source, $failed_at_earleme);
    }
    my $evaler = new Parse::Marpa::Evaluator($recce);
    return unless defined $evaler;
    my $value = $evaler->next();
    raw_grammar_eval($grammar, $value);
}

sub Parse::Marpa::Grammar::set {
    my $grammar = shift;
    my ($args)    = @_;

    local ($Parse::Marpa::Internal::This::grammar) = $grammar;
    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[Parse::Marpa::Internal::Grammar::PHASE];
    my $interface = $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];

    # value of source needs to be a *REF* to a string
    my $source = $args->{"mdl_source"};
    if ( defined $source ) {
        croak("Cannot source grammar with some rules already defined")
            if $phase != Parse::Marpa::Internal::Phase::NEW;
        croak("Source for grammar must be specified as string ref")
            unless ref $source eq "SCALAR";
        croak("Source for grammar undefined")
            if not defined $$source;
        source_grammar( $grammar, $source, $args->{"source_options"} );
	delete $args->{"mdl_source"};
        delete $args->{"source_options"};
    }

    while ( my ( $option, $value ) = each %$args ) {
        given ($option) {
            when ("rules") {
		$grammar-> [Parse::Marpa::Internal::Grammar::INTERFACE]
		    //= Parse::Marpa::Internal::Interface::RAW;
		my $interface = $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];
                croak("rules option not allowed with " . interface_description($interface))
                    if $interface ne Parse::Marpa::Internal::Interface::RAW;
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                add_user_rules( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
                    Parse::Marpa::Internal::Phase::RULES;
            }
            when ("terminals") {
		$grammar-> [Parse::Marpa::Internal::Grammar::INTERFACE]
		    //= Parse::Marpa::Internal::Interface::RAW;
		my $interface = $grammar->[Parse::Marpa::Internal::Grammar::INTERFACE];
                croak("terminals option not allowed with " . interface_description($interface))
                    if $interface ne Parse::Marpa::Internal::Interface::RAW;
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                add_user_terminals( $grammar, $value );
                $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
                    Parse::Marpa::Internal::Phase::RULES;
            }
            when ("start") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::START] = $value;
            }
            when ("academic") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::ACADEMIC] =
                    $value;
            }
            when ("default_null_value") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_NULL_VALUE] =
                    $value;
            }
            when ("default_action") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::DEFAULT_ACTION] =
                    $value;
            }
            when ("default_lex_prefix") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_PREFIX] =
                    $value;
            }
            when ("default_lex_suffix") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar
                    ->[Parse::Marpa::Internal::Grammar::DEFAULT_LEX_SUFFIX] =
                    $value;
            }
            when ("ambiguous_lex") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
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
		if ($value) {
		    say $trace_fh "Setting $option option";
		    say $trace_fh "Warning: setting $option option after semantics were finalized"
			if $phase >= Parse::Marpa::Internal::Phase::EVALED;
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_lex") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ]
                    = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ]
                    = $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_lex_tries") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_TRIES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_lex_matches") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_LEX_MATCHES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_values") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_VALUES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_rules") {
                $grammar->[Parse::Marpa::Internal::Grammar::TRACE_RULES] =
                    $value;
		if ($value) {
		    my $rules = $grammar->[Parse::Marpa::Internal::Grammar::RULES];
		    my $rule_count = @$rules;
		    say $trace_fh "Setting $option";
		    say $trace_fh "Warning: Setting $option when $rule_count rules already exist"
		       if $rule_count;
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
		}
            }
            when ("trace_strings") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_STRINGS ] =
                    $value;
		if ($value) {
		    my $rules = $grammar->[Parse::Marpa::Internal::Grammar::RULES];
		    my $rule_count = @$rules;
		    say $trace_fh "Setting $option";
		    say $trace_fh "Warning: Setting $option after $rule_count rules have been defined"
		       if $rule_count;
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
		}
            }
            when ("trace_predefineds") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PREDEFINEDS ] =
                    $value;
		if ($value) {
		    my $rules = $grammar->[Parse::Marpa::Internal::Grammar::RULES];
		    my $rule_count = @$rules;
		    say $trace_fh "Setting $option";
		    say $trace_fh "Warning: Setting $option after $rule_count rules have been defined"
		       if $rule_count;
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
		}
            }
            when ("trace_evaluation_choices") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_EVALUATION_CHOICES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_iterations") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ]
                    = $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ]
                    = $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_iteration_searches") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_SEARCHES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_iteration_changes") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_ITERATION_CHANGES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("trace_priorities") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_PRIORITIES ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option";
		    say $trace_fh "Warning: Setting $option after semantics were finalized"
			if $phase >= Parse::Marpa::Internal::Phase::EVALED;
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING  ] = 1;
		}
            }
            when ("trace_completions") {
                $grammar->[ Parse::Marpa::Internal::Grammar::TRACE_COMPLETIONS ] =
                    $value;
		if ($value) {
		    say $trace_fh "Setting $option option";
		    $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ] = 1;
		}
            }
            when ("location_callback") {
                croak("location callback not yet implemented");
            }
            when ("opaque") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                given ($value) {
                    when (1) { $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE] = 1; }
                    when (0) {
                        my $old_opaque = $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE];
                        if (defined $old_opaque and $old_opaque) {
                            croak("opaque cannot be unset once it has been set");
                        }
                        $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE] = 0;
                    }
                    default { croak("opaque must be set to either 0 or 1"); }
                } 
            }
            when ("warnings") {
                say $trace_fh qq{"warnings" option is useless after grammar is precomputed}
                    if $value && $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[Parse::Marpa::Internal::Grammar::WARNINGS] =
                    $value;
            }
            when ("online") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::EVALED;
                $grammar->[Parse::Marpa::Internal::Grammar::ONLINE] =
                    $value;
            }
            when ("code_lines") {
                $grammar->[Parse::Marpa::Internal::Grammar::CODE_LINES] =
                    $value;
            }
            when ("allow_raw_source") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::RULES;
                $grammar->[Parse::Marpa::Internal::Grammar::ALLOW_RAW_SOURCE ] =
                    $value;
            }
            when ("max_parses") {
                $grammar->[Parse::Marpa::Internal::Grammar::MAX_PARSES ] =
                    $value;
            }
            when ("version") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[ Parse::Marpa::Internal::Grammar::VERSION ] =
                    $value;
            }
            when ("semantics") {
                croak("$option option not allowed after grammar is precomputed")
                    if $phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED;
                $grammar->[ Parse::Marpa::Internal::Grammar::SEMANTICS ] =
                    $value;
            }
            when ("preamble") {
                croak(
		    "$option option not allowed in ",
		    Parse::Marpa::Internal::Phase::description($phase)
		) if $phase >= Parse::Marpa::Internal::Phase::EVALED;
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

sub Parse::Marpa::Grammar::precompute {
    my $grammar = shift;

    my $tracing = $grammar->[Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[ Parse::Marpa::Internal::Grammar::PHASE ];
    if ($phase >= Parse::Marpa::Internal::Phase::PRECOMPUTED) {
	croak(
	    "Attempt to precompute grammar in inappropriate state\nAttempt to precompute ",
	    Parse::Marpa::Internal::Phase::description($phase)
	);
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
        for my $symbol ( @{ Parse::Marpa::Grammar::inaccessible_symbols($grammar) } ) {
            say $trace_fh "Inaccessible symbol: $symbol";
        }
        for my $symbol ( @{ Parse::Marpa::Grammar::unproductive_symbols($grammar) } ) {
            say $trace_fh "Unproductive symbol: $symbol";
        }
    }

    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::PRECOMPUTED;
    $grammar;
}

sub Parse::Marpa::Grammar::show_problems {
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
sub Parse::Marpa::Grammar::compile {
    my $grammar = shift;

    my $tracing = $grammar->[ Parse::Marpa::Internal::Grammar::TRACING ];
    my $trace_fh;
    if ($tracing) {
        $trace_fh = $grammar->[Parse::Marpa::Internal::Grammar::TRACE_FILE_HANDLE];
    }

    my $phase = $grammar->[ Parse::Marpa::Internal::Grammar::PHASE ];
    if ($phase > Parse::Marpa::Internal::Phase::COMPILED
	    or $phase < Parse::Marpa::Internal::Phase::RULES)
    {
	croak(
	    "Attempt to compile grammar in inappropriate state\nAttempt to compile ",
	    Parse::Marpa::Internal::Phase::description($phase)
	);
    }

    if ($phase == Parse::Marpa::Internal::Phase::RULES) {
        Parse::Marpa::Grammar::precompute($grammar);
    }

    my $problems = $grammar->[Parse::Marpa::Internal::Grammar::PROBLEMS];
    if ($problems) {
        croak(
            Parse::Marpa::Grammar::show_problems($grammar),
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
sub Parse::Marpa::Grammar::decompile {
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
            Parse::Marpa::Internal::die_on_problems(
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
    $grammar->[Parse::Marpa::Internal::Grammar::PHASE] =
        Parse::Marpa::Internal::Phase::COMPILED;
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

sub Parse::Marpa::Grammar::show_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    my $text    = "";
    for my $symbol_ref (@$symbols) {
        $text .= Parse::Marpa::show_symbol($symbol_ref);
    }
    $text;
}

sub Parse::Marpa::Grammar::show_nulling_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::NULLING] }
            @$symbols );
}

sub Parse::Marpa::Grammar::show_nullable_symbols {
    my $grammar = shift;
    my $symbols =
        $grammar->[Parse::Marpa::Internal::Grammar::NULLABLE_SYMBOL];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] } @$symbols );
}

sub Parse::Marpa::Grammar::show_productive_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::PRODUCTIVE] }
            @$symbols );
}

sub Parse::Marpa::Grammar::show_accessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    join( " ",
        sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { $_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @$symbols );
}

sub Parse::Marpa::Grammar::inaccessible_symbols {
    my $grammar = shift;
    my $symbols = $grammar->[Parse::Marpa::Internal::Grammar::SYMBOLS];
    [   sort map { $_->[Parse::Marpa::Internal::Symbol::NAME] }
            grep { !$_->[Parse::Marpa::Internal::Symbol::ACCESSIBLE] }
            @$symbols
    ];
}

sub Parse::Marpa::Grammar::unproductive_symbols {
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

sub Parse::Marpa::Grammar::show_rules {
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

sub Parse::Marpa::Grammar::show_NFA {
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

sub Parse::Marpa::Grammar::show_SDFA {
    my $grammar = shift;
    my $text    = "";
    my $SDFA    = $grammar->[Parse::Marpa::Internal::Grammar::SDFA];
    for my $state (@$SDFA) { $text .= Parse::Marpa::show_SDFA_state($state); }
    $text;
}

sub Parse::Marpa::Grammar::show_ii_SDFA {
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

sub Parse::Marpa::Grammar::get_symbol {
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

            # no change to @_ needed for action
            if ( defined $separator_name and not $keep_separation ) {
                $action = q{ $_ = [
                        @{$_}[
                           grep { !($_ % 2) } (0 .. $#$_)
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
                $rule_action = q{ $_ = []; } . $action;
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

    # The following rules make evaluations opaque
    $grammar->[Parse::Marpa::Internal::Grammar::OPAQUE] = 1;

    my $rule_action;
    given ($action) {
        when (undef) { $rule_action = undef; }
        default {
            if ($left_associative) {

                # more efficient way to do this?
                $rule_action = q{
                    HEAD: for (;;) {
                        my $head = shift @$_;
                        last HEAD unless scalar @$head;
                        unshift(@$_, @$head);
                    }
                }
            }
            else {
                $rule_action = q{
                    TAIL: for (;;) {
                        my $tail = pop @$_;
                        last TAIL unless scalar @$tail;
                        push(@$_, @$tail);
                    }
                }
            }
            $rule_action .= $action;
        }
    }
    add_rule( $grammar, $lhs, [$sequence], $rule_action, $priority, );
    if ( defined $separator and not $proper_separation ) {
        unless ($keep_separation) {
            $rule_action = q{ pop @$_; } . ($rule_action // "") ;
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
                    @{$_}[
                        grep { !($_ % 2) } (0 .. $#$_)
                    ]
                ]
            }
        }
        else {
            $rule_action = q{
                unshift(@$_, []);
                $_ 
            }
        }
    }
    else {
        if ( defined $separator and not $keep_separation ) {
            $rule_action = q{
                [
                    @{$_}[
                        grep { !($_ % 2) } (0 .. $#$_)
                    ],
                    []
                ]
            }
        }
        else {
            $rule_action = q{
                push(@$_, []);
                $_ 
            }
        }
    }

    add_rule( $grammar, $sequence, $counted_rhs, $rule_action, $priority, );

    # iterating sequence rule
    $rule_action = ( defined $separator and not $keep_separation )
        ? q{
            [
                @{$_}[
                   grep { !($_ % 2) } (0 .. $#$_)
                ],
            ]
        }
        : q{
            $_
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
        = ( $productive, 1, 1, q{ $_->[0] } );

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

1;

=pod

=head1 NAME

Parse::Marpa::Grammar - Marpa Grammar Objects

=head1 DESCRIPTION

Grammar objects are created with the C<new> constructor.
Rules and options may be specified when the grammar is created, or later using
the C<set> method.
Rules are most conveniently added with the C<mdl_source> named argument, which
takes a reference to a string containing an MDL grammar description as its value.
MDL (the Marpa Description Language) is detailed in L<another document|Parse::Marpa::Doc::MDL>.

MDL indirectly uses another interface, the B<plumbing interface>.
Users who want the last word in control can use the plumbing directly,
but they will lose a lot of convenience and maintainability.
Those who need the ultimate in efficiency can get the best of both worlds by
using MDL to create a grammar,
then compiling that grammar,
as L<described below|"compile">.
The plumbing is described in L<a document of its own|Parse::Marpa::Doc::Plumbing>.
The MDL parser itself uses a compiled MDL file.

Marpa needs to do extensive precompution on grammars
before they can be passed on to a recognizer or an evaluator.
The user rarely needs to perform this precomputation explicitly.
The methods which require precomputed grammars
(C<compile> and C<Parse::Marpa::Recognizer::new>),
do the precomputation themselves on a just-in-time basis.

For situations where the user needs to control the state of the grammar precisely,
such as debugging or tracing,
there is a method that explicitly precomputes a grammar: C<precompute>.
Once a grammar has been precomputed, it is frozen against many kinds of
changes.
For example, you cannot add rules to a precomputed grammar.

For their private use,
Marpa recognizers make a deep copy of the the grammar used to create them.
The deep copy is done by B<compiling> the grammar, then B<decompiling> the grammar.

Grammar compilation in Marpa means turning the grammar into a string with
Marpa's C<compile> method.
Since a compiled grammar is a string, it can be handled as one.
It can, for instance, be written to a file.

Marpa's C<decompile> static method takes a compiled grammar,
C<eval>'s it,
then tweaks it a bit to create a properly set-up grammar object.
A subsequent Marpa process can read this file, C<decompile> the string,
and continue the parse.
This would eliminate the overhead both of parsing MDL and of precomputation.
As mentioned, where efficiency is a major consideration, this will
usually be better than using the
plumbing interface.

=head1 METHODS

=head2 new

    my $grammar = Parse::Marpa::Grammar::new({ trace_rules => 1 });

Z<>

    my $grammar = new Parse::Marpa::Grammar({});

Z<>

    my $grammar = new Parse::Marpa::Grammar({
	mdl_source => \$mdl_source,
	ambiguous_lex => 0
    });

C<Parse::Marpa::Recognizer::new> has one, required, argument --
a reference to a hash of named arguments.
It returns a new grammar object or throws an exception.

Named arguments can be Marpa options.
For these see L<Parse::Marpa/OPTIONS>.
In addition to the Marpa options,
the C<mdl_source> named argument
and the named arguments of the plumbing interface are allowed.
For details of the plumbing and its named arguments, see L<Parse::Marpa::Doc::Plumbing>.

The value of the C<mdl_source> named argument should be
a B<reference> to a string containing a description of
the grammar in the L<Marpa Demonstration Language|Parse::Marpa::MDL>.
Either the C<mdl_source> named argument or the plumbing arguments may be used
to build a grammar,
but both cannot be used to build the same grammar object.

In the C<new> and C<set> methods,
a Marpa option can be specified both directly,
as a named argument to the method,
and indirectly,
in the MDL grammar description supplied as the value of an C<mdl_source> argument.
When that happens, the value in the MDL description is applied first,
and value supplied with the method's named argument is applied after the MDL is processed.
This fits the usual intent, which is for named arguments to override MDL settings.
However, this also
means that trace settings won't be in effect until after the grammar description is
processed, and that can be too late for some of the traces.
For a way around this, see L<the C<set> method|"set">.

=head2 set

    Parse::Marpa::Grammar::set($grammar, { trace_lex => 1 });

    $g->set({ mdl_source => \$source });

The C<set> method takes as its one, required, argument a reference to a hash of named arguments.
It allows Marpa options, plumbing arguments and the C<mdl_source> named argument
to be specified for an already existing grammar object.
It can be used to control the order in which the named arguments are applied.

In particular, some
tracing options need to be turned on prior to specifying the grammar.
To do this, an new grammar object can be created with the trace options set,
but without a grammar specification.
At this point, tracing will be in effect,
and the C<set> method can be used to specify the grammar,
using either the C<mdl_source> named argument or the plumbing
arguments.

=head2 precompute

    $grammar->precompute();

    Parse::Marpa::Grammar::precompute($grammar);

The C<precompute> method performs Marpa's precomputations on a grammar.
It returns the grammar object or throws an exception.

It is usually not necessary for the user to call C<precompute>.
The methods which require a precomputed grammar
(C<compile> and C<Parse::Marpa::Recognizer::new>),
if passed a grammar on which the precomputations have not been done,
perform the precomputation themselves on a "just in time" basis.
But C<precompute> can be useful in debugging and tracing,
as a way to control precisely when precomputation takes place.

=head2 compile

    my $compiled_grammar = $grammar->compile();

    my $compiled_grammar = Parse::Marpa::Grammar::compile($grammar);

The C<compile> method takes as its single argument a grammar object, and "compiles" it.
It returns a reference to the compiled grammar.
The compiled grammar is a string which was created 
using L<Data::Dumper>.
On failure, C<compile> throws an exception.

=head2 decompile

    $grammar = Parse::Marpa::Grammar::decompile($compiled_grammar, $trace_fh);

    $grammar = Parse::Marpa::Grammar::decompile($compiled_grammar);

The C<decompile> static method takes a reference to a compiled grammar as its first
argument.
Its second, optional, argument is a file handle.
The file handle argument will be used both as the decompiled grammar's trace file handle,
and for any trace messages produced by C<decompile> itself.
C<decompile> returns the decompiled grammar object unless it throws an
exception.

If the trace file handle argument is omitted,
it defaults to C<STDERR>
and the decompiled grammar's trace file handle reverts to the default for a new
grammar, which is also C<STDERR>.
The trace file handle argument is necessary because in the course of compilation,
the grammar's original trace file handle may have been lost.
For example, a compiled grammar can be written to a file and emailed.
Marpa cannot rely on finding the original trace file handle available and open
when a compiled grammar is decompiled.

When Marpa deep copies grammars internally, it uses the C<compile> and C<decompile> methods.
To preserve the trace file handle of the original grammar,
Marpa first copies the handle to a temporary,
then restores the handle using the C<trace_file_handle> argument of C<decompile>.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
