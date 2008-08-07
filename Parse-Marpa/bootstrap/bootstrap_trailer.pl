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
	say STDERR "Parsing exhausted at line ", $line+1, ", earleme $earleme";
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

sub slurp { open(my $fh, '<', shift); local($RS); <$fh>; }

my $header = slurp($header_file_name) if $header_file_name;
my $trailer = slurp($trailer_file_name) if $trailer_file_name;

say "# This file was automatically generated using Parse::Marpa ", $Parse::Marpa::VERSION;
my $value = $evaler->value();
print $header if defined $header;
say $$value;
print $trailer if defined $trailer;

# This is the end of bootstrap_trailer.pl
