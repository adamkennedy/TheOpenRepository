#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

my @h = ( );
my @h2 = ( );
foreach my $t (qw(test TEST foo foo Test)) {
    my $h1 = node->head1($t);
    push @h, $h1;
    foreach my $t (qw(TEST biscuit test cheese)) {
        $h1->push(node->head2($t));
    }
}
my $root = node->root;
$root->nest(@h);

my @ci =  # case insensitive
    $root->select('/head1[@heading =~ {test}i]');
my @cs =  # case sensitive
    $root->select('/head1[@heading =~ {TEST}]');
my @eq =  # equality - simple
    $root->select('/head1[@heading = \'Test\']');
my @ec =  # equality - complex
    $root->select('/head1[@heading = /head2@heading]');
my @ec_s = # equality - complex - successor
    $root->select('/head1[>>@heading = @heading]');
my @root = # Only one root node for all:
    $root->select('//^'); # Horribly ineffient NOP. This catches the
                          # filter_unique behaviour.

# Match head2 nodes which match top level head1 nodes -
# expands/restricts a lot of nodes.
my @tt = $root->select('//head2[@heading = ^/head1@heading]');

ok(@cs == 1, "Case sensitive match 1");
ok(@ci == 3, "Case insensitive match 3");
ok(@eq == 1, "Exact match 1");
ok(@ec == 2, "Complex match 2");
ok(@ec_s == 1, "Complex Successor match 1");
ok($_->detach, "Detach matched node") foreach @ec_s;

my @ec_p = # equality - complex - preceding
    $root->select('/head1[<<@heading = @heading]');

ok(@ec_p == 0, "Complex Preceding match 0");
ok(@root == 1, "One root node only");
ok(@tt == 10, "Match 10 head2 nodes");

1;

