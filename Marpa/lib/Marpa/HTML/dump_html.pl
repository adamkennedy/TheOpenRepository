#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;

use HTML::TokeParser;

my $p = HTML::TokeParser->new(\*STDIN) || Carp::croak( "Can't open: $!" );

$p->empty_element_tags(1);  # configure its behaviour

my @marpa_tokens = ();
while ( my $token = $p->get_token ) {
    given ( shift @{$token} ) {
        when ('E') {
            push @marpa_tokens, [ 'End_' . $token->[0], $token->[1] ]
        }
        when ('S') {
            push @marpa_tokens, [ 'Start_' . $token->[0], $token->[3] ]
        }
        when ('PI') {

            # deal with CDATA and entities
            push @marpa_tokens, [ 'PI', $token->[0] ]
        }
        when ('C') {

            # deal with CDATA and entities
            push @marpa_tokens, [ 'Comment', $token->[0] ]
        }
        when ('D') {

            # deal with CDATA and entities
            push @marpa_tokens, [ 'Declaration', $token->[0] ]
        }
        when ('T') {

            # deal with CDATA and entities
            push @marpa_tokens, [ 'Text', $token->[0] ]
        }
    } ## end given
} ## end while ( my $token = $p->get_token )

# say Data::Dumper::Dumper(\@marpa_tokens);
say join "\n", map { $_->[0] } @marpa_tokens;
