# Marpa compiling its own specification language
# New generations of this file will usually be created by 
# replacing everything after this comment with bootcopy1.pl,
# then hacking it by hand as needed
# to bootstrap the new self.marpa.

# This file was automatically generated using Parse::Marpa 0.211005
# This is the beginning of bootstrap_header.pl

use 5.010_000;
use strict;
use warnings;
use Parse::Marpa;
use Parse::Marpa::MDL;
use Carp;
use English qw( -no_match_vars ) ;

my %regex;

my $new_terminals = [];
my $new_rules = [];
my $new_preamble;
my $new_lex_preamble;
my $new_start_symbol;
my $new_semantics;
my $new_version;
my $new_default_action;
my $new_default_null_value;
my $new_default_lex_prefix;
our %strings;

sub usage {
   die("usage: $0 grammar-file\n");
}

my $argc = @ARGV;
usage() unless $argc >= 1 and $argc <= 3;

my $grammar_file_name = shift @ARGV;
my $header_file_name = shift @ARGV;
my $trailer_file_name = shift @ARGV;
$header_file_name //= "bootstrap_header.pl";
$trailer_file_name //= "bootstrap_trailer.pl";

our $GRAMMAR;
open(GRAMMAR, "<", $grammar_file_name) or die("Cannot open $grammar_file_name: $!");

# This is the end of bootstrap_header.pl
$new_semantics = 'perl5';

$new_version = '0.211006';

$new_start_symbol = "grammar";

$new_default_lex_prefix = qr/(?:[ \t]*(?:\n|(?:\#[^\n]*\n)))*[ \t]*/;

$strings{"concatenate-lines"} =  q{
    my $v_count = scalar @_;
    return undef if $v_count <= 0;
    join("\n", grep { $_ } @_);
};

$new_preamble .=  q{
    our $regex_data = [];
};

push(@$new_rules, {
    lhs => "grammar"
,    rhs => ["paragraphs"],
    action =>   q{ $_[0] },
,
,

});
push(@$new_rules, {
    lhs => "grammar"
,    rhs => ["paragraphs", "whitespace-lines"],
    action =>   q{ $_[0] },
,
,

});
push(@$new_rules, {
    lhs => "paragraphs"
,rhs => ["paragraph"],
separator => "empty-line",
min => 1,
,
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "paragraph"
,    rhs => ["definition-paragraph"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "paragraph"
,    rhs => ["production-paragraph"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "paragraph"
,    rhs => ["terminal-paragraph"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "definition-paragraph"
,rhs => ["definition"],
min => 1,
,
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "production-paragraph"
,    rhs => ["non-structural-production-sentences", "production-sentence", "non-structural-production-sentences", "action-sentence:optional", "non-structural-production-sentences"],
    action => 
    q{
        my $action = $_[3];
        my $other_key_value = join(",\n", map { $_ // "" } @_[0,2,4]);
        my $result =
            'push(@$new_rules, '
             . "{\n"
             . $_[1] . ",\n"
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
    },
,
,

});
push(@$new_rules, 
    { lhs => "action-sentence:optional",  rhs => [ "action-sentence" ], 
                     min => 0,
                     max => 1,
                     action => q{ scalar @_ ? $_[0] : undef }
             },
 );

push(@$new_rules, {
    lhs => "non-structural-production-sentences"
,rhs => ["non-structural-production-sentence"],
min => 0,
,
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "non-structural-production-sentence"
,    rhs => ["priority:k0", "integer", "period"],
    action => 
q{ q{ priority => } . $_[1] },
,
,

});
push(@$new_terminals,
    ["priority:k0" => { regex => qr/priority/ }],
);

push(@$new_rules, {
    lhs => "action-sentence"
,    rhs => ["the:k1:optional", "action:k2", "is:k3", "action-specifier", "period"],
    action => 
q{
    "    action => "
    . $_[3]
},
,
,

});
push(@$new_terminals,
    ["the:k1" => { regex => qr/the/ }],
    ["action:k2" => { regex => qr/action/ }],
    ["is:k3" => { regex => qr/is/ }],
);

push(@$new_rules, 
    { lhs => "the:k1:optional",  rhs => [ "the:k1" ], 
                     min => 0,
                     max => 1,
                     action => q{ scalar @_ ? $_[0] : undef }
             },
 );

push(@$new_rules, {
    lhs => "action-sentence"
,    rhs => ["action-specifier", "period"],
    action => 
q{
    "    action => "
    . $_[0]
},
,
,

});
push(@$new_rules, {
    lhs => "action-specifier"
,    rhs => ["string-specifier"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "non-structural-production-sentence"
,    rhs => ["comment-sentence"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "non-structural-terminal-sentence"
,    rhs => ["comment-sentence"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "definition"
,    rhs => ["predefined-setting", "period"],
    action =>   q{ $_[0] },
,
,
 priority => 1000
});
push(@$new_rules, {
    lhs => "definition"
,    rhs => ["comment-sentence"],
,
,

});
push(@$new_rules, {
    lhs => "definition"
,    rhs => ["bracketed-comment"],
,
,

});
push(@$new_rules, {
    lhs => "definition"
,    rhs => ["string-definition"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["default-action-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["default-null-value-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["preamble-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["lex-preamble-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["semantics-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["version-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["start-symbol-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "predefined-setting"
,    rhs => ["default-lex-prefix-setting"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "semantics-setting"
,    rhs => ["the:k1:optional", "semantics:k4", "copula", "perl5:k5"],
    action => 
     q{
         q{$new_semantics = '}
         . $_[3]
        . qq{';\n}
},
,
,

});
push(@$new_terminals,
    ["semantics:k4" => { regex => qr/semantics/ }],
    ["perl5:k5" => { regex => qr/perl5/ }],
);

push(@$new_rules, {
    lhs => "semantics-setting"
,    rhs => ["perl5:k5", "copula", "the:k1:optional", "semantics:k4"],
    action => 
q{
    q{$new_semantics = '}
    . $_[0]
    . qq{';\n}
},
,
,

});
push(@$new_rules, {
    lhs => "version-setting"
,    rhs => ["the:k1:optional", "version:k6", "copula", "version-number"],
    action => 
q{
    q{$new_version = '}
    . Parse::Marpa::MDL::canonical_version($_[3])
    . qq{';\n}
},
,
,

});
push(@$new_terminals,
    ["version:k6" => { regex => qr/version/ }],
);

push(@$new_rules, {
    lhs => "version-setting"
,    rhs => ["version%20number:k7", "copula", "the:k1:optional", "version:k6"],
    action => 
q{
    q{$new_version = '}
    . Parse::Marpa::MDL::canonical_version($_[0])
    . qq{';\n}
},
,
,

});
push(@$new_terminals,
    ["version%20number:k7" => { regex => qr/version number/ }],
);

push(@$new_rules, {
    lhs => "start-symbol-setting"
,    rhs => ["the:k1:optional", "start:k8", "symbol:k9", "copula", "symbol-phrase"],
    action => 
q{
    q{$new_start_symbol = "}
    . $_[4]
    . qq{";\n}
},
,
,

});
push(@$new_terminals,
    ["start:k8" => { regex => qr/start/ }],
    ["symbol:k9" => { regex => qr/symbol/ }],
);

push(@$new_rules, {
    lhs => "start-symbol-setting"
,    rhs => ["symbol-phrase", "copula", "the:k1:optional", "start:k8", "symbol:k9"],
    action => 
q{
    q{$new_start_symbol = }
    . $_[0]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "default-lex-prefix-setting"
,    rhs => ["regex", "copula", "the:k1:optional", "default:ka", "lex:kb", "prefix:kc"],
    action => 
q{
             q{$new_default_lex_prefix = }
             . $_[0]
             . qq{;\n}
},
,
,

});
push(@$new_terminals,
    ["default:ka" => { regex => qr/default/ }],
    ["lex:kb" => { regex => qr/lex/ }],
    ["prefix:kc" => { regex => qr/prefix/ }],
);

push(@$new_rules, {
    lhs => "default-lex-prefix-setting"
,    rhs => ["the:k1:optional", "default:ka", "lex:kb", "prefix:kc", "copula", "regex"],
    action => 
q{
    q{$new_default_lex_prefix = }
    . $_[5]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "default-null-value-setting"
,    rhs => ["string-specifier", "copula", "the:k1:optional", "default:ka", "null:kd", "value:ke"],
    action => 
q{
             q{$new_default_null_value = }
             . $_[0]
             . qq{;\n}
},
,
,

});
push(@$new_terminals,
    ["null:kd" => { regex => qr/null/ }],
    ["value:ke" => { regex => qr/value/ }],
);

push(@$new_rules, {
    lhs => "default-null-value-setting"
,    rhs => ["the:k1:optional", "default:ka", "null:kd", "value:ke", "copula", "string-specifier"],
    action => 
q{
    q{$new_default_null_value = }
    . $_[5]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "preamble-setting"
,    rhs => ["a:kf", "preamble:k10", "is:k3", "string-specifier"],
    action => 
q{
    q{$new_preamble .= }
    . $_[3]
    . qq{;\n}
},
,
 priority => 1000,

});
push(@$new_terminals,
    ["a:kf" => { regex => qr/a/ }],
    ["preamble:k10" => { regex => qr/preamble/ }],
);

push(@$new_rules, {
    lhs => "preamble-setting"
,    rhs => ["string-specifier", "is:k3", "a:kf", "preamble:k10"],
    action => 
q{
    q{$new_preamble .= }
    . $_[0]
    . qq{;\n}
},
,
 priority => 1000,

});
push(@$new_rules, {
    lhs => "lex-preamble-setting"
,    rhs => ["a:kf", "lex:kb", "preamble:k10", "is:k3", "string-specifier"],
    action => 
q{
    q{$new_lex_preamble .= }
    . $_[3]
    . qq{;\n}
},
,
 priority => 1000,

});
push(@$new_rules, {
    lhs => "preamble-setting"
,    rhs => ["string-specifier", "is:k3", "a:kf", "lex:kb", "preamble:k10"],
    action => 
q{
    q{$new_lex_preamble .= }
    . $_[0]
    . qq{;\n}
},
,
 priority => 1000,

});
push(@$new_rules, {
    lhs => "copula"
,    rhs => ["is:k3"],
,
,

});
push(@$new_rules, {
    lhs => "copula"
,    rhs => ["are:k11"],
,
,

});
push(@$new_terminals,
    ["are:k11" => { regex => qr/are/ }],
);

push(@$new_rules, {
    lhs => "string-definition"
,    rhs => ["symbol-phrase", "is:k3", "string-specifier", "period"],
    action => 
q{
    '$strings{"'
    . $_[0]
    . '"} = '
    . $_[2]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "default-action-setting"
,    rhs => ["action-specifier", "is:k3", "the:k1:optional", "default:ka", "action:k2"],
    action => 
q{
    q{ $new_default_action = }
    . $_[0]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "default-action-setting"
,    rhs => ["the:k1:optional", "default:ka", "action:k2", "is:k3", "action-specifier"],
    action => 
q{
    q{ $new_default_action = }
    . $_[4]
    . qq{;\n}
},
,
,

});
push(@$new_rules, {
    lhs => "comment-sentence"
,    rhs => ["comment-tag", "%3a:k12", "comment-words", "period"],
,
,

});
push(@$new_terminals,
    ["%3a:k12" => { regex => qr/:/ }],
);

push(@$new_rules, {
    lhs => "comment-words"
,rhs => ["comment-word"],
min => 1,
,
,
,

});
push(@$new_rules, {
    lhs => "literal-string"
,    rhs => ["q-string"],
    action =>   q{ $_[0] },
,
,

});
push(@$new_rules, {
    lhs => "literal-string"
,    rhs => ["double-quoted-string"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "literal-string"
,    rhs => ["single-quoted-string"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "production-sentence"
,    rhs => ["lhs", "production-copula", "rhs", "period"],
    action => 
q{
    $_[0]
    . "\n,"
    . $_[2]
},
,
,

});
push(@$new_rules, {
    lhs => "production-copula"
,    rhs => ["%3a:k12"],
,
,

});
push(@$new_rules, {
    lhs => "production-copula"
,    rhs => ["%3a%3a%3d:k13"],
,
,

});
push(@$new_terminals,
    ["%3a%3a%3d:k13" => { regex => qr/::=/ }],
);

push(@$new_rules, {
    lhs => "symbol-phrase"
,rhs => ["symbol-word"],
min => 1,
,
    action => 
q{ Parse::Marpa::MDL::canonical_symbol_name(join("-", @_)) },
,
,

});
push(@$new_rules, {
    lhs => "lhs"
,    rhs => ["symbol-phrase"],
    action => 
q{ '    lhs => "' . $_[0] . q{"} },
,
,

});
push(@$new_rules, {
    lhs => "rhs"
,    rhs => [],
    action => 
q{ "    rhs => []" },
,
,

});
push(@$new_rules, {
    lhs => "rhs"
,rhs => ["rhs-element"],
separator => "comma",
min => 1,
,
    action => 
q{ "    rhs => [" . join(", ", @_) . "]" },
,
,

});
push(@$new_rules, {
    lhs => "rhs"
,    rhs => ["symbol-phrase", "sequence:k14"],
    action => 
q{
    q{rhs => ["}
    . $_[0]
    . qq{"],\n}
    . qq{min => 1,\n}
},
,
 priority => 1000,

});
push(@$new_terminals,
    ["sequence:k14" => { regex => qr/sequence/ }],
);

push(@$new_rules, {
    lhs => "rhs"
,    rhs => ["optional:k15", "symbol-phrase", "sequence:k14"],
    action => 
q{
    q{rhs => ["}
    . $_[1]
    . qq{"],\n}
    . qq{min => 0,\n}
},
,
 priority => 2000,

});
push(@$new_terminals,
    ["optional:k15" => { regex => qr/optional/ }],
);

push(@$new_rules, {
    lhs => "rhs"
,    rhs => ["symbol-phrase", "separated:k16", "symbol-phrase", "sequence:k14"],
    action => 
q{
    q{rhs => ["}
    . $_[2]
    . qq{"],\n}
    . q{separator => "}
    . $_[0]
    . qq{",\n}
    . qq{min => 1,\n}
},
,
 priority => 2000,

});
push(@$new_terminals,
    ["separated:k16" => { regex => qr/separated/ }],
);

push(@$new_rules, {
    lhs => "rhs"
,    rhs => ["optional:k15", "symbol-phrase", "separated:k16", "symbol-phrase", "sequence:k14"],
    action => 
q{
    q{rhs => ["}
    . $_[3]
    . qq{"],\n}
    . q{separator => "}
    . $_[1]
    . qq{",\n}
    . qq{min => 0,\n}
},
,
 priority => 3000,

});
push(@$new_rules, {
    lhs => "rhs-element"
,    rhs => ["mandatory-rhs-element"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "rhs-element"
,    rhs => ["optional-rhs-element"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "mandatory-rhs-element"
,    rhs => ["rhs-symbol-specifier"],
    action => 
q{ q{"} . $_[0] . q{"} },
,
,

});
push(@$new_rules, {
    lhs => "optional-rhs-element"
,    rhs => ["optional:k15", "rhs-symbol-specifier"],
    action => 
q{
     my $symbol_phrase = $_[1];
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
                     action => q{ scalar @_ ? $_[0] : undef }
             }
         );
     }
     q{"} . $optional_symbol_phrase . q{"};
},
,
,

});
push(@$new_rules, {
    lhs => "rhs-symbol-specifier"
,    rhs => ["symbol-phrase"],
    action => 
q{ $_[0] },
,
,

});
push(@$new_rules, {
    lhs => "rhs-symbol-specifier"
,    rhs => ["regex"],
    action => 
q{
    our $regex_data;
    my $regex = $_[0];
    my ($symbol, $new) = Parse::Marpa::MDL::gen_symbol_from_regex($regex, $regex_data);
    if ($new) {
        our @implicit_terminals;
        push(@implicit_terminals,
            q{"}
            . $symbol
            . '" => { regex => '
            . $regex
            . " }"
        );
    }
    $symbol;
},
,
,

});
push(@$new_rules, {
    lhs => "terminal-paragraph"
,    rhs => ["non-structural-terminal-sentences", "terminal-sentence", "non-structural-terminal-sentences"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "non-structural-terminal-sentences"
,rhs => ["non-structural-terminal-sentence"],
min => 0,
,
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "terminal-sentence"
,    rhs => ["symbol-phrase", "matches:k17", "regex", "period"],
    action => 
q{
    q{push(@$new_terminals, [ "}
    . $_[0]
    . q{" => }
    . "{ regex => "
    . $_[2]
    . "}"
    . qq{ ] );\n}
},
,
,

});
push(@$new_terminals,
    ["matches:k17" => { regex => qr/matches/ }],
);

push(@$new_rules, {
    lhs => "terminal-sentence"
,    rhs => ["match:k18", "symbol-phrase", "using:k19", "string-specifier", "period"],
    action => 
q{
    q{push(@$new_terminals, [ "}
    . $_[1]
    . q{" => }
    . "{ action => "
    . $_[3]
    . "}"
    . qq{ ] );\n}
},
,
,

});
push(@$new_terminals,
    ["match:k18" => { regex => qr/match/ }],
    ["using:k19" => { regex => qr/using/ }],
);

push(@$new_rules, {
    lhs => "string-specifier"
,    rhs => ["literal-string"],
    action => $strings{ "concatenate-lines" },
,
,

});
push(@$new_rules, {
    lhs => "string-specifier"
,    rhs => ["symbol-phrase"],
    action => 
q{
    '$strings{ "'
    . $_[0]
    . '" }'
},
,
,

});
push(@$new_rules, {
    lhs => "whitespace-lines"
,rhs => ["whitespace-line"],
min => 1,
,
,
,

});
push(@$new_terminals, [ "q-string" => { action => "lex_q_quote"} ] );

push(@$new_terminals, [ "regex" => { action => "lex_regex"} ] );

push(@$new_terminals, [ "empty-line" => { regex => qr/^[ \t]*\n/m} ] );

push(@$new_terminals, [ "bracketed-comment" => { regex => qr/\x{5b}[^\x{5d}]*\x{5d}/} ] );

push(@$new_terminals, [ "single-quoted-string" => { action =>  q{
    my $match_start = pos $$STRING;
    state $prefix_regex = qr/\G'/o;
    return unless $$STRING =~ /$prefix_regex/g;
    state $regex = qr/\G[^'\0134]*('|\0134')/;
    MATCH: while ($$STRING =~ /$regex/gc) {
        next MATCH unless defined $1;
        if ($1 eq q{'}) {
            my $end_pos = pos $$STRING;
            my $match_length = $end_pos - $match_start;
            my $lex_length = $end_pos - $START;
            return (substr($$STRING, $match_start, $match_length), $lex_length);
        }
    }
    return;
}} ] );

push(@$new_terminals, [ "double-quoted-string" => { action =>  q{
    my $match_start = pos $$STRING;
    state $prefix_regex = qr/\G"/o;
    return unless $$STRING =~ /$prefix_regex/g;
    state $regex = qr/\G[^"\0134]*("|\0134")/;
    MATCH: while ($$STRING =~ /$regex/gc) {
        next MATCH unless defined $1;
        if ($1 eq q{"}) {
            my $end_pos = pos $$STRING;
            my $match_length = $end_pos - $match_start;
            my $lex_length = $end_pos - $START;
            return (substr($$STRING, $match_start, $match_length), $lex_length);
        }
    }
    return;
}} ] );

push(@$new_terminals, [ "version-number" => { regex => qr/(\d+\.)*\d+/} ] );

push(@$new_terminals, [ "symbol-word" => { regex => qr/[a-zA-Z_][a-zA-Z0-9_-]*/} ] );

push(@$new_terminals, [ "period" => { regex => qr/\./} ] );

push(@$new_terminals, [ "integer" => { regex => qr/\d+/} ] );

push(@$new_terminals, [ "comment-tag" => { regex => qr/(to\s+do|note|comment)/} ] );

push(@$new_terminals, [ "comment-word" => { regex => qr/[\x{21}-\x{2d}\x{2f}-\x{7e}]+/} ] );

push(@$new_terminals, [ "comma" => { regex => qr/\,/} ] );

push(@$new_terminals, [ "whitespace-line" => { regex => qr/^[ \t]*(?:\#[^\n]*)?\n/m} ] );

# This is the beginning of bootstrap_trailer.pl

$new_start_symbol //= "(undefined start symbol)";
$new_semantics //= "not defined";
$new_version //= -1;

croak("Version requested is ", $new_version, "\nVersion must match ", $Parse::Marpa::VERSION, " exactly.")
   unless $new_version == $Parse::Marpa::VERSION;

croak("Semantics are ", $new_semantics, "\nThe only semantics currently available are perl5.")
   unless $new_semantics eq "perl5";

my $g = new Parse::Marpa::Grammar({
    start => $new_start_symbol,
    rules => $new_rules,
    terminals => $new_terminals,
    warnings => 1,
});

$g->set({default_lex_prefix => $new_default_lex_prefix})
    if defined $new_default_lex_prefix;
$g->set({default_action => $new_default_action})
    if defined $new_default_action;
$g->set({default_null_value => $new_default_null_value})
    if defined $new_default_null_value;

my $recce = new Parse::Marpa::Recognizer({
   grammar=> $g,
   preamble => $new_preamble,
   lex_preamble => $new_lex_preamble,
});

sub locator {
    my $earleme = shift;
    my $string = shift;

    state $lines;
    $lines = [0];
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

our $HEADER;
my $header;
{ local($RS) = undef; open(HEADER, "<", $header_file_name); $header = <HEADER>; }

our $TRAILER;
my $trailer;
{ local($RS) = undef; open(TRAILER, "<", $trailer_file_name); $trailer = <TRAILER>; }

say "# This file was automatically generated using Parse::Marpa ", $Parse::Marpa::VERSION;
my $value = $evaler->next();
print $header, $$value, "\n", $trailer;

# This is the end of bootstrap_trailer.pl
