use 5.010;
use strict;
use warnings;
use English;
use Text::Diff;

local($RS);
my $file = <STDIN>;
my ($got, $expected);
($got, $expected) = $file =~ m/
    [#]\s+got:[ ]'(.*)\n
    [#][ ]'\n
    [#]\s+expected:[ ]'(.*)\n
    [#][ ]'\n
/xms;
my $diff = diff \$got, \$expected;
say $diff;
