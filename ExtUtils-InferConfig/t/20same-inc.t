#!perl
use strict;
use warnings;
use Test::More tests => scalar(grep {not ref($_)} @INC) + 4;

use_ok('ExtUtils::InferConfig');

my $eic = ExtUtils::InferConfig->new(
    perl => $^X
);
isa_ok($eic, 'ExtUtils::InferConfig');

my $inc = $eic->get_inc;
ok(ref($inc) eq 'ARRAY', '->get_inc returns array ref');

my @local_inc = grep {not ref($_)} @INC;
ok(
    scalar(@local_inc) == scalar(@$inc),
    'Same number of non-ref @INC entries'
);


foreach my $path (@local_inc) {
    my $inc_path = shift @$inc;
    is($inc_path, $path);
}

