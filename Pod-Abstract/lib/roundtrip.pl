#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract::Parser;
use Pod::Abstract::Path;
use Pod::Abstract;
use Data::Dumper;

my $root = Pod::Abstract->load_filehandle(\*STDIN);

# Point this at Pod/Abstract.pm to see the node manipulation work!
my ($target) = $root->select("//target(0)");
my @headings = $root->select("/head1");

my @new_nodes = ( );
foreach my $head (@headings) {
    my $i = Pod::Abstract::Node->new(
        type => 'test', body => $head->param('heading')->pod,
        );
    push @new_nodes,$i;
}

if($target) {
    $target->nest(@new_nodes);
    $target->hoist;
    $target->detach;
}

print $root->pod;

