#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract::Parser;
use Pod::Abstract::Path;
use Pod::Abstract;
use Data::Dumper;
use Pod::Abstract::BuildNode qw(node nodes);

my $root = Pod::Abstract->load_filehandle(\*STDIN);

# Point this at Pod/Abstract.pm to see the node manipulation work!
my ($target) = $root->select("//target(0)");
my @headings = $root->select("/head1");

my @new_nodes = ( );
my $list = node->over;
foreach my $head (@headings) {
    my $i = node->item('*');
    $i->push(node->paragraph($head->param('heading')->pod));
    push @new_nodes,$i;
}
$list->nest(@new_nodes);

if($target) {
    $target->nest($list);
    $target->hoist;
    $target->detach;
}

print $root->pod;

