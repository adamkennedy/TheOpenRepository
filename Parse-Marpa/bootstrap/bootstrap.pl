# Marpa compiling its own specification language

use 5.010_000;
use strict;
use warnings;
use English;
use lib "../lib";
use Parse::Marpa;
use Parse::Marpa::MDL;
use Carp;
use Fatal qw(open close);

sub usage {
   die("usage: $0 grammar-file header trailer\n");
}

usage() unless scalar @ARGV == 3;

my $grammar_file_name = shift @ARGV;
my $header_file_name  = shift @ARGV;
my $trailer_file_name = shift @ARGV;

our $GRAMMAR; # to silence spurious warning
open(GRAMMAR, "<", $grammar_file_name) or die("Cannot open $grammar_file_name: $!");

my $discard = undef;

my $concatenate_lines = q{
    my $v_count = scalar @$_;
    return undef if $v_count <= 0;
    join("\n", grep { $_ } @$_);
};

our $whitespace = qr/(?:[ \t]*(?:\n|(?:\#[^\n]*\n)))*[ \t]*/;
our $default_lex_prefix = $whitespace;

my $preamble = <<'EOCODE';
    our %strings;
    our $regex_data = [];
EOCODE

my %regex;

# URL escaping
my $rules = [
    [ "grammar", [ "paragraph sequence" ], $concatenate_lines ],
    [ "grammar", [ "paragraph sequence", "whitespace lines" ], $concatenate_lines ],
    {
        lhs => "paragraph sequence",
        rhs => [ "paragraph" ],
        action => $concatenate_lines,
        min => 1,
        separator => "empty line",
    },
    # change definition to another word?
    [ "paragraph", [ "empty paragraph" ] ],
    [ "paragraph", [ "definition paragraph" ], $concatenate_lines ],
    [ "paragraph", [ "production paragraph" ], $concatenate_lines ],
    [ "paragraph", [ "terminal paragraph" ], $concatenate_lines ],
    [ "empty paragraph", [ "whitespace" ] ],
    {
	lhs => "comment paragraph",
	rhs => [ "comment" ],
	min => 1,
	action => $concatenate_lines,
    },
    {
	lhs => "definition paragraph",
	rhs => [ "definition" ],
	min => 1,
	action => $concatenate_lines,
    },
    [ "production paragraph",
       [
	 "non structural production sentences",
         "production sentence",
	 "non structural production sentences",
         "optional action sentence",
	 "non structural production sentences",
	],
        q{
            my $action = $_->[3];
            my $other_key_value = join(",\n", map { $_ // "" } @{$_}[0,2,4]);
	    my $result =
                'push(@$new_rules, '
                . "{\n"
                . $_->[1] . ",\n"
                . (defined $action ? ($action . ",\n") : "")
                . $other_key_value
                . "\n});"
            ;
            our @implicit_terminals;
            if (@implicit_terminals) {
                $result .= "\n" . 'push(@$new_terminals,' . "\n";
                while (my $implicit_terminal = shift @implicit_terminals) {
                    $result .= "    [" . $implicit_terminal . "],\n";
                }
                $result .= ");\n";
            }
            our @implicit_rules;
            if (@implicit_rules) {
                $result .= "\n" . 'push(@$new_rules, ' . "\n";
                while (my $implicit_production = shift @implicit_rules) {
                    $result .= "    {" . $implicit_production . "},\n";
                }
                $result .= " );\n";
            }
            $result;
	}
    ],
    { 
       lhs => "non structural production sentences",
       rhs => [ "non structural production sentence" ],
       min => 0,
       action => $concatenate_lines,
    },
    {
       lhs => "non structural production sentence",
       rhs => [ "priority keyword", "integer", "period" ],
       action => q{ q{ priority => } . $_->[1] },
    },
    {
       lhs => "optional action sentence",
       rhs => [ "action sentence" ],
       min => 0,
       max => 1,
       action => $concatenate_lines,
    },
    [ "action sentence",
	[
	    "optional the keyword",
	    "action keyword",
	    "is keyword",
	    "action specifier",
	    "period",
	],
	q{
           "    action => "
           . $_->[3]
        }
    ],
    [ "action sentence",
	[
	    "action specifier",
	    "period",
	],
	q{
           "    action => "
           . $_->[0]
        }
    ],
    [ "action specifier", [ "string specifier" ], $concatenate_lines ],
    [ "non-structural production sentence", [ "comment sentence", ], $concatenate_lines, ],
    [ "non-structural terminal sentence", [ "comment sentence", ], $concatenate_lines, ],
    [
        "definition",
        [ "setting", "period" ],
        q{ $_->[0] }
    ],
    [ "definition", [ "comment sentence", ] ],
    [ "definition", [ "bracketed comment", ] ],
    [ "definition", [ "default action definition", ], $concatenate_lines, ],
    [ "definition", [ "string definition", ], $concatenate_lines, ],
    [ "definition", [ "preamble definition", ], $concatenate_lines, 1000 ],
    [ "setting", [ "semantics setting" ], $concatenate_lines, ],
    [ "setting", [ "version setting" ], $concatenate_lines, ],
    [ "setting", [ "start symbol setting" ], $concatenate_lines, ],
    [ "setting", [ "default lex prefix setting" ], $concatenate_lines, ],
    [ "semantics setting",
	[
 	  "optional the keyword",
  	  "semantics keyword", 
	  "copula",
  	  "perl5 keyword", 
	],
        q{
            q{$new_semantics = '}
            . $_->[3]
            . qq{';\n}
        }
    ],
    [ "semantics setting",
	[
  	  "perl5 keyword", 
	  "copula",
 	  "optional the keyword",
  	  "semantics keyword", 
	],
        q{
            q{$new_semantics = '}
            . $_->[0]
            . qq{';\n}
        }
    ],
    [ "version setting",
	[
 	  "optional the keyword",
  	  "version keyword", 
	  "copula",
  	  "version number", 
	],
        q{
            q{$new_version = '}
            . Parse::Marpa::MDL::canonical_version($_->[3])
            . qq{';\n}
        }
    ],
    [ "version setting",
	[
  	  "version number", 
	  "copula",
 	  "optional the keyword",
  	  "version keyword", 
	],
        q{
            q{$new_version = '}
            . Parse::Marpa::MDL::canonical_version($_->[0])
            . qq{';\n}
        }
    ],
    [ "start symbol setting",
	[
 	  "optional the keyword",
  	  "start keyword", 
  	  "symbol keyword", 
	  "copula",
  	  "symbol phrase", 
	],
        q{
            q{$new_start_symbol = "}
            . $_->[4]
            . qq{";\n}
        }
    ],
    [ "start symbol setting",
	[
  	  "symbol phrase", 
	  "copula",
 	  "optional the keyword",
  	  "start keyword", 
  	  "symbol keyword", 
	],
        q{
            q{$new_start_symbol = }
            . $_->[0]
            . qq{;\n}
        }
    ],
    [ "default lex prefix setting",
	[
  	  "regex", 
	  "copula",
 	  "optional the keyword",
  	  "default keyword", 
  	  "lex keyword", 
  	  "prefix keyword", 
	],
        q{
            q{$new_default_lex_prefix = }
            . $_->[0]
            . qq{;\n}
        }
    ],
    [ "default lex prefix setting",
	[
 	  "optional the keyword",
  	  "default keyword", 
  	  "lex keyword", 
  	  "prefix keyword", 
	  "copula",
  	  "regex", 
	],
        q{
            q{$new_default_lex_prefix = }
            . $_->[5]
            . qq{;\n}
        }
    ],
    [ "copula", [ "is keyword" ] ],
    [ "copula", [ "are keyword" ] ],
    [ "string definition",
	[ "symbol phrase", "is keyword", "string specifier",
	  "period"
        ],
        q{
            '$strings{"'
            . $_->[0]
            . '"} = '
            . $_->[2]
            . qq{;\n}
        }
    ],
    [
        "preamble definition",
        [ "a keyword", "preamble keyword", "is keyword", "string specifier", "period" ],
        q{
            q{$new_preamble .= }
            . $_->[3]
            . qq{;\n}
        }
    ],
    [ "default action definition",
	[
            "action specifier",
            "is keyword",
            "optional the keyword",
            "default keyword",
            "action keyword",
	    "period",
	],
        q{
            q{$new_default_action = }
            . $_->[0]
            . qq{;\n}
        }
    ],
    {
       lhs => "optional the keyword",
       rhs => [ "the keyword" ],
       min => 0,
       max => 1,
    },
    [ "comment sentence", [ "comment tag", "colon", "comment word sequence", "period" ], $discard ],
    {
       lhs => "comment word sequence",
       rhs => [ "comment word" ],
       # action => $discard,
       min => 0,
    },
    [ "text segment", [ "pod block" ], $discard, ],
    [ "text segment", [ "comment" ], $discard, ],
    [
        "literal string",
        [ "q string" ],
        q{ $_->[0] }
    ],
    [ "literal string", [ "double quoted string" ], $concatenate_lines, ],
    [ "literal string", [ "single quoted string" ], $concatenate_lines, ],
    [ "pod block",
        [
	    "pod head",
	    "pod body",
	    "pod cut",
	],
	$discard,
    ],
    {
       lhs => "pod body",
       rhs => [ "pod line" ],
       # action => $discard,
       min => 0,
    },
    {
	lhs => "production sentence",
	rhs => [ "lhs", "colon", "rhs", "period" ],
        # join(",\n", @{$_}[0,2])
	action => q{
	    $_->[0]
            .  ",\n"
            . (
                $_->[2] //
                "rhs => []"
            )
	},
    },
    {
	lhs => "symbol phrase",
	rhs => [ "symbol word" ],
	action => q{ Parse::Marpa::MDL::canonical_symbol_name(join("-", @$_)) },
	min => 1,
    },
    {
        lhs => "lhs",
	rhs => [ "symbol phrase" ],
	action => q{ '    lhs => "' . $_->[0] . q{"} },
    },
    {
        lhs => "rhs",
	rhs => [ ],
	action => q{ "    rhs => []" },
    },
    {
        lhs => "rhs",
	rhs => [ "rhs element" ],
	action => q{ "    rhs => [" . join(", ", @$_) . "]" },
	min => 1,
	separator => "comma",
    },
    {
        lhs => "rhs",
	rhs => [ "symbol phrase", "sequence keyword" ],
        priority => 1000,
        action => q{
            q{rhs => ["}
            . $_->[0]
            . qq{"],\n}
            . qq{min => 1,\n}
        }
    },
    {
        lhs => "rhs",
	rhs => [ "optional keyword", "symbol phrase", "sequence keyword" ],
        priority => 2000,
        action => q{
            q{rhs => ["}
            . $_->[1]
            . qq{"],\n}
            . qq{min => 0,\n}
        }
    },
    {
        lhs => "rhs",
	rhs => [ "symbol phrase", "separated keyword", "symbol phrase", "sequence keyword" ],
        priority => 2000,
        action => q{
            q{rhs => ["}
            . $_->[2]
            . qq{"],\n}
            . q{separator => "}
            . $_->[0]
            . qq{",\n}
            . qq{min => 1,\n}
        }
    },
    {
        lhs => "rhs",
	rhs => [
            "optional keyword",
            "symbol phrase", "separated keyword",
            "symbol phrase", "sequence keyword"
        ],
        priority => 3000,
        action => q{
            q{rhs => ["}
            . $_->[3]
            . qq{"],\n}
            . q{separator => "}
            . $_->[1]
            . qq{",\n}
            . qq{min => 0,\n}
        }
    },
    {
        lhs => "rhs element",
        rhs => [ "mandatory rhs element", ],
        action => $concatenate_lines,
    },
    {
        lhs => "rhs element",
        rhs => [ "optional rhs element", ],
        action => $concatenate_lines,
    },
    {
        lhs => "mandatory rhs element",
	rhs => [ "rhs symbol specifier" ],
        action => q{ q{"} . $_->[0] . q{"} },
    },
    {
        lhs => "optional rhs element",
	rhs => [ "optional keyword", "rhs symbol specifier" ],
	action => q{
            my $symbol_phrase = $_->[1];
            my $optional_symbol_phrase = $symbol_phrase . ":optional";
            our %implicit_rules;
            if (not defined $implicit_rules{$optional_symbol_phrase}) {
                $implicit_rules{$optional_symbol_phrase} = 1;
                our @implicit_rules;
                push(
                    @implicit_rules,
                    q{ lhs => "} . $optional_symbol_phrase . q{", }
                    . q{ rhs => [ "} . $symbol_phrase . qq{" ], }
                    . q{
                            min => 0,
                            max => 1,
                            action => q{ $_->[0] }
                    }
                );
            }
            q{"} . $optional_symbol_phrase . q{"};
        },
    },
    {
        lhs => "rhs symbol specifier",
	rhs => [ "symbol phrase" ],
	action => q{ $_->[0] },
    },
    {
        lhs => "rhs symbol specifier",
	rhs => [ "regex", ],
	action => q{
            our $regex_data;
            my $regex = $_->[0];
            my ($symbol, $new) = Parse::Marpa::MDL::gen_symbol_from_regex($regex, $regex_data);
            our @implicit_terminals;
            if ($new) {
                push(@implicit_terminals,
                    q{"}
                    . $symbol
                    . '" => { regex => '
                    . $regex
                    . " }"
                );
            }
            $symbol;
        }
    },
    {
        lhs => "optional period",
	rhs => [ "period" ],
	# action => $discard,
	min => 0,
	max => 1,
    },
    [ "terminal paragraph",
       [
	 "non structural terminal sentences",
         "terminal sentence",
	 "non structural terminal sentences",
	],
	$concatenate_lines,
    ],
    { 
       lhs => "non structural terminal sentences",
       rhs => [ "non structural terminal sentence" ],
       min => 0,
       action => $concatenate_lines,
    },
    {
        lhs => "terminal sentence",
	rhs => [ "symbol phrase", "matches keyword", "regex", "period" ],
	action => q{
	    q{push(@$new_terminals, [ "}
	    . $_->[0]
	    . q{" => }
            . "{ regex => "
	    . $_->[2]
            . " }"
            . qq{ ] );\n}
	}
    },
    {
        lhs => "terminal sentence",
	rhs => [ "match keyword", "symbol phrase", "using keyword", "string specifier", "period" ],
	action => q{
	    q{push(@$new_terminals, [ "}
	    . $_->[1]
	    . q{" => }
            . "{ action => "
	    . $_->[3]
            . " }"
            . qq{ ] );\n}
	}
    },
    [ "string specifier", [ "literal string" ], $concatenate_lines ],
    [
        "string specifier",
        [ "symbol phrase" ],
        q{
            '$strings{ "'
	    . $_->[0]
            . '" }'
        }
    ],
    { 
        lhs => "whitespace lines",
        rhs => [ "whitespace line" ],
        min => 1,
        # action => $discard,
    }
];


my $terminals = [
    [ "a keyword"            => { regex => qr/a/ } ],
    [ "action keyword"       => { regex => qr/action/ } ],
    [ "as keyword"           => { regex => qr/as/ } ],
    [ "are keyword"          => { regex => qr/are/ } ],
    [ "default keyword"      => { regex => qr/default/ } ],
    [ "define keyword"       => { regex => qr/define/ } ],
    [ "is keyword"           => { regex => qr/is/ } ],
    [ "lex keyword"          => { regex => qr/lex/ } ],
    [ "match keyword"        => { regex => qr/match/ } ],
    [ "matches keyword"      => { regex => qr/matches/ } ],
    [ "optional keyword"     => { regex => qr/optional/ } ],
    [ "perl5 keyword"        => { regex => qr/perl5/ } ],
    [ "prefix keyword"       => { regex => qr/prefix/ } ],
    [ "preamble keyword"     => { regex => qr/preamble/ } ],
    [ "priority keyword"     => { regex => qr/priority/ } ],
    [ "separated keyword"    => { regex => qr/separated/ } ],
    [ "sequence keyword"     => { regex => qr/sequence/ } ],
    [ "semantics keyword"    => { regex => qr/semantics/ } ],
    [ "start keyword"        => { regex => qr/start/ } ],
    [ "symbol keyword"       => { regex => qr/symbol/ } ],
    [ "the keyword"          => { regex => qr/the/ } ],
    [ "using keyword"        => { regex => qr/using/ } ],
    [ "version keyword"      => { regex => qr/version/ } ],
    [ "q string"             => { action => "lex_q_quote" } ],
    [ "regex"                => { action => "lex_regex" } ],
    [ "empty line"           => { regex => qr/^[ \t]*\n/m } ],
    [ "bracketed comment"    => { regex => qr/\x{5b}[^\x{5d}]*\x{5d}/ } ],
    # change to lex_q_quote
    [ "single quoted string" => {
        action => q{
                state $prefix_regex = qr/\G'/o;
                return unless $$STRING =~ /$prefix_regex/g;
                state $regex = qr/\G[^'\0134]*('|\0134')/;
                MATCH: while ($$STRING =~ /$regex/gc) {
                    next MATCH unless defined $1;
                    if ($1 eq q{'}) {
                        my $length = (pos $$STRING) - $START;
                        return (substr($$STRING, $START, $length), $length);
                    }
                }
                return;
            }
        }
    ],
    [ "double quoted string" => {
            action => q{
                state $prefix_regex = qr/\G"/o;
                return unless $$STRING =~ /$prefix_regex/g;
                state $regex = qr/\G[^"\0134]*("|\0134")/;
                MATCH: while ($$STRING =~ /$regex/gc) {
                    next MATCH unless defined $1;
                    if ($1 eq q{"}) {
                        my $length = (pos $$STRING) - $START;
                        return (substr($$STRING, $START, $length), $length);
                    }
                }
                return;
            }
        }
    ],
    [ "pod head"             => { regex => qr/^=[a-zA-Z_].*$/m } ],
    [ "pod cut"              => { regex => qr/^=cut.*$/m } ],
    [ "pod line"             => { regex => qr/.*\n/m } ],
    [ "version number"       => { regex => qr/(\d+\.)*\d+/ }, ],
    [ "comment"              => { regex => qr/#.*\n/}, ],
    [ "symbol word"          => { regex => qr/[a-zA-Z_][a-zA-Z0-9_-]*/ }, ], 
    [ "period"               => { regex => qr/\./ }, ], 
    [ "colon"                => { regex => qr/\:/ }, ], 
    [ "integer"              => { regex => qr/\d+/ }, ],

    # Do I want to allow comments between "to" and "do" ?
    [ "comment tag" => { regex => qr/(to\s+do|note|comment)/ }, ],

    # Includes all non-whitespace printable characters except period
    [ "comment word" => { regex => qr/[\x{21}-\x{2d}\x{2f}-\x{7e}]+/ }, ],

    [ "comma"                => { regex => qr/\,/ }, ], 
    [ "whitespace line"      => { regex => qr/^[ \t]*(?:\#[^\n]*)?\n/m }, ],
];

for my $terminal_rule (@$terminals) {
    $terminal_rule->[0] = Parse::Marpa::MDL::canonical_symbol_name($terminal_rule->[0]);
}

for my $rule (@$rules) {
    given (ref $rule) {
        when ("ARRAY") {
	    $rule->[0] = Parse::Marpa::MDL::canonical_symbol_name($rule->[0]);
	    my $rhs = $rule->[1];
	    my $new_rhs = [];
	    for my $symbol (@$rhs) {
		push(@$new_rhs, Parse::Marpa::MDL::canonical_symbol_name($symbol));
	    }
	    $rule->[1] = $new_rhs;
	}
	when ("HASH") {
	     for (keys %$rule) {
	         when ("lhs") { $rule->{$_} = Parse::Marpa::MDL::canonical_symbol_name($rule->{$_}) }
	         when ("rhs") {
		     my $new_rhs = [];
		     for my $symbol (@{$rule->{$_}}) {
			 push(@$new_rhs, Parse::Marpa::MDL::canonical_symbol_name($symbol));
		     }
		     $rule->{$_} = $new_rhs;
		 }
	         when ("separator") { $rule->{$_} = Parse::Marpa::MDL::canonical_symbol_name($rule->{$_}) }
	     }
	}
	default { croak ("Invalid rule ref: ", ($_ ? $_ : "undefined")) }
    }
}

my $g = new Parse::Marpa::Grammar({
    start => Parse::Marpa::MDL::canonical_symbol_name("grammar"),
    rules => $rules,
    terminals => $terminals,
    # default_action => $default_action,
    # ambiguous_lex => 0,
    default_lex_prefix => $default_lex_prefix,
    # trace_rules => 1,
    preamble => $preamble,
    warnings => 0,
});

my $recce = new Parse::Marpa::Recognizer(
   { grammar=> $g }
);

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

    state $lines;
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

my $spec;

{
    local($RS) = undef;
    $spec = <GRAMMAR>;
    if ((my $earleme = $recce->text(\$spec)) >= 0) {
        # for the editors, line numbering starts at 1
        # do something about this?
	my ($line, $line_start) = locator($earleme, \$spec);
	say STDERR "Parse exhausted at line ", $line+1, ", earleme $earleme";
	given (index($spec, "\n", $line_start)) {
	    when (undef) { say STDERR substr($spec, $line_start) }
	    default { say STDERR substr($spec, $line_start, $_-$line_start) }
	}
	say STDERR +(" " x ($earleme-$line_start)), "^";
	exit 1;
    }
}

my $evaler = new Parse::Marpa::Evaluator($recce);
die("No parse") unless $evaler;

our $HEADER; # to silence spurious warning
my $header;
{ open(HEADER, "<", $header_file_name); local($RS) = undef; $header = <HEADER>; }

our $TRAILER; # to silence spurious warning
my $trailer;
{ open(TRAILER, "<", $trailer_file_name); local($RS) = undef; $trailer = <TRAILER>; }

my $value = $evaler->next();
print $header, $$value, $trailer;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
