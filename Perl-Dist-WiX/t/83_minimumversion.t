#!perl

use strict;
use warnings;

use Test::More;

use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'No TEST_AUTHOR: Skipping author test';
    plan skip_all => $msg;
}

eval { require Test::MinimumVersion; };

plan skip_all => 
    'Test::MinimumVersion required for testing for version numbers' if $EVAL_ERROR;

Test::MinimumVersion->import();
all_minimum_version_from_metayml_ok();