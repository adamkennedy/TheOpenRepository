use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English qw( -no_match_vars ) ;
use Config;
use IPC::Open2;
use Fatal qw(chdir open close);
use File::Compare;

use Test::More tests => 1;

my $example_dir = $PROGRAM_NAME =~ m{t/} ? "example" : "../example";
chdir($example_dir);

my $this_perl = $^X; 

our $DOC;
open(DOC, "<", "../lib/Parse/Marpa/Doc/Internals.pod");
my $doc; { local($RS) = undef; $doc = <DOC>; }
$doc =~ s/\A.*^=head2[ ]The[ ]MDL[ ]Grammar\n$//xms;
$doc =~ s/^=.*\z//xms;
$doc =~ s/^\s*$//xmsg;
$doc =~ s/^\s+//xmsg;

our $EXAMPLE;
open(EXAMPLE, "<", "equation.marpa");
my $example; { local($RS) = undef; $example = <EXAMPLE>; }
$example =~ s/^\s*$//xmsg;
$example =~ s/^\s+//xmsg;

my @doc = split(/\n/, $doc);
my @example = split(/\n/, $example);
my $ok = 1;
if (@doc != @example) {
   diag("strings differ in length: ", (scalar @doc), " vs. ", (scalar @example));
   $ok = 0;
} else {
    COMPARE: while (1) {
	my $doc = shift @doc;
	last COMPARE unless defined $doc;
	my $example = shift @example;
	if ($doc ne $example) {
	    diag("Mismatch, line 1: ", $doc);
	    diag("Mismatch, line 2: ", $example);
	    $ok = 0;
	    last COMPARE;
	}
    }
}
ok($ok, "equation grammar vs. Internals.pod");
