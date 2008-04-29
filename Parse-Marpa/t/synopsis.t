use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English qw( -no_match_vars ) ;
use Config;
use IPC::Open2;

use Test::More;

if ($Config{"d_fork"}) {
    plan tests => 2;
} else {
    plan skip_all => "Fork required to test examples";
    exit 0;
}

my $example_dir = $PROGRAM_NAME =~ m{t/} ? "example" : "../example";
chdir($example_dir);

my $this_perl = $^X; 
local($RS) = undef;

open(PIPE, "-|", $this_perl, "-I../lib", "synopsis.pl")
    or die("Cannot open pipe: $!");
is(<PIPE>, "12\n", "synopsis example");
close(PIPE);

$ENV{PERL5LIB} = "../lib:" . $ENV{PERL5LIB};
my $pid = open2(\*PIPE, \*TEXT, $this_perl, "../bin/mdl", "parse", "-grammar", "../example/null_value.marpa");
say TEXT "Z";
close(TEXT);
is(<PIPE>, "A is missing, but Zorro was here\n", "null value example");
close(PIPE);
waitpid($pid, 0);
