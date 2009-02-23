#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

my $pa = Pod::Abstract->load_filehandle(\*STDIN);
my @macro_nodes = $pa->select('//begin[.=~{^define}]');
my %macros = ( );
foreach my $macro (@macro_nodes) {
    $macro->detach; # Don't leave it in the tree.
    $macro->body =~ m/^define (.+)$/;
    my $m_name = $1;
    $macros{$m_name} = $macro;
}

my @macro_use = $pa->select('//use');
foreach my $m_u (@macro_use) {
    my $m_name = $m_u->body;
    if(my $macro = $macros{$m_name}) {
        $macro->select_into($m_u, "/");
        $m_u->hoist;
    } else {
        node->text("No macro defined '$m_name'")->insert_after($m_u);
    }
    $m_u->detach;
}

print $pa->pod;

1;
