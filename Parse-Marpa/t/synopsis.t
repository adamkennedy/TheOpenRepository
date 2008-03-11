use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;
use Config;

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

open(PIPE, "-|", $this_perl, "-I../lib", "null_value.pl")
    or die("Cannot open pipe: $!");
is(<PIPE>, "A is missing, but Zorro was here\n", "null value example");
