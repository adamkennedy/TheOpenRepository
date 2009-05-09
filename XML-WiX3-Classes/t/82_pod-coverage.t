#!perl

use Test::More;
eval "require Pod::Coverage::Moose";
plan skip_all => "Pod::Coverage::Moose 0.01 required for testing POD coverage" if $@;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose'});
