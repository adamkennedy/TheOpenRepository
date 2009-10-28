#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw( -no_match_vars ) ;

use Marpa::UrHTML;

my $document = do { local $RS = undef; <main::STDIN> };

my $p = Marpa::UrHTML->new(\$document) || Carp::croak( "Can't open: $!" );

$p->empty_element_tags(1);  # configure its behaviour

my $marpa_tokens = $p->value();

# say Data::Dumper::Dumper($marpa_tokens);

say join "\n", map { $_->[0] } @{$marpa_tokens};
