#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

my $pa = Pod::Abstract->load_filehandle(\*STDIN);

my $h1 = 0;
my @h1 = $pa->select('/head1');
foreach my $hn1 (@h1) {
    $h1 ++;
    $hn1->param('heading')->unshift(node->text("$h1. "));
    
    my @h2 = $hn1->select('/head2');
    my $h2 = 0;
    foreach my $hn2 (@h2) {
        $h2 ++;
        $hn2->param('heading')->unshift(node->text("$h1.$h2 "));
        
        my @h3 = $hn2->select('/head3');
        my $h3 = 0;
        foreach my $hn3 (@h3) {
            $h3 ++;
            $hn3->param('heading')->unshift(node->text("$h1.$h2.$h3 "));

            my @h4 = $hn3->select('/head4');
            my $h4 = 0;
            foreach my $hn4 (@h4) {
                $h4 ++;
                $hn4->param('heading')->
                    unshift(node->text("$h1.$h2.$h3.$h4 "));
            }
        }
    }
}

print $pa->pod;
