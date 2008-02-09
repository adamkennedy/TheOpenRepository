use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;
use Config;
# use Fatal qw(open close);

use Test::More tests => 1;

unless ($Config{"d_pipe"}) {
    plan skip_all => "Pipes required to test examples";
    exit 0;
}

my $example_dir = $0 =~ m{t/} ? "example" : "../example";
chdir($example_dir);

my $this_perl = $^X; 
our $PIPE;
open(PIPE, "-|", $this_perl, "-I../lib", "synopsis.pl")
    or die("Cannot open pipe: $!");
local($RS) = undef;
my $result = <PIPE>;
is($result, "12\n", "synopsis example");
