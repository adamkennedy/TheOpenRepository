#!perl -w
use strict;
use lib 'lib';
use Config;
use Test::More tests => scalar(keys(%Config))*2 + 4;

use_ok('ExtUtils::InferConfig');

my $eic = ExtUtils::InferConfig->new(
    perl => $^X
);
isa_ok($eic, 'ExtUtils::InferConfig');

my $cfg = $eic->get_config;
ok(ref($cfg) eq 'HASH', '->Config returns hash ref');

is(
    scalar(keys(%Config)), scalar(keys(%$cfg)),
    'Same number of config entries'
);


foreach my $key (keys %$cfg) {
    ok(exists($Config{$key}), "Key '$key' exists in both configs");
    is($cfg->{$key}, $Config{$key}, "Value for key '$key' same in both configs.");
}

