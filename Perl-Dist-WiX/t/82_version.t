#!perl

use strict;
use warnings;

use Test::More;

use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'No TEST_AUTHOR: Skipping author test';
    plan( skip_all => $msg );
}

eval { require Test::HasVersion; };

plan skip_all => 
    'Test::HasVersion required for testing for version numbers' if $EVAL_ERROR;

Test::HasVersion->import();
all_pm_version_ok();