#!perl

use strict;
use warnings;

use Test::More;

use File::Spec::Functions qw(catfile);
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'No TEST_AUTHOR: Skipping author test';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

eval { require Perl::Critic::More; };

if ( $EVAL_ERROR ) {
   my $msg = 'Perl::Critic::More required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = catfile( 't', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( -profile => $rcfile, -severity => 1 );
all_critic_ok();