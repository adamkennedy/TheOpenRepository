#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

my $pa = Pod::Abstract->load_filehandle(\*STDIN);

my @toc_target = $pa->select('//toc');
unless(@toc_target) {
    die "Please include an =toc command where you would like a TOC\n";
}
unless(scalar @toc_target == 1) {
    die "Only one =toc command per file please\n";
}

my @h1 = $pa->select('/head1');
my $toc_top = node->over;

sub do_headings {
    my $target = shift;
    my $level = shift;
    $level = 1 unless defined $level;
    my @nodes = @_;
    
    if(@nodes) {
        my $toc_over = node->over;
        $target->push($toc_over);
        foreach my $node(@nodes) {
            my $item = node->item('*');
            my $label = 
                node->paragraph("L</".$node->param('heading')->pod.">");
            $toc_over->push($item);
            $item->push($label);
            my $next_level = $level + 1;
            my @next = $node->select("/head$next_level");
            do_headings($item,$next_level,@next);
        }
    }
}

do_headings($toc_top,1,@h1);

$toc_top->insert_after($toc_target[0]);
$toc_target[0]->detach;

print $pa->pod;
