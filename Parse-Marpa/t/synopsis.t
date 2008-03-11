use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;
use Config;
use IPC::Open2;

use Test::More tests => 2;

unless ($Config{"d_pipe"}) {
    plan skip_all => "Pipes required to test examples";
    exit 0;
}

my $example_dir = $0 =~ m{t/} ? "example" : "../example";
chdir($example_dir);

my $this_perl = $^X; 
local($RS) = undef;

open(PIPE, "-|", $this_perl, "-I../lib", "synopsis.pl")
    or die("Cannot open pipe: $!");
is(<PIPE>, "12\n", "synopsis example");
close(PIPE);

$ENV{PERL5LIB} .= ":../lib";
my $pid = open2(\*PIPE, \*TEXT, "../bin/marpa", "parse", "-grammar", "../example/null_value.marpa");
say TEXT "Z";
close(TEXT);
is(<PIPE>, "A is missing, but Zorro was here\n", "null value example");
close(PIPE);
waitpid($pid, 0);
