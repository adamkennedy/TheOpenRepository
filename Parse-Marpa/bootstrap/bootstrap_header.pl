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
