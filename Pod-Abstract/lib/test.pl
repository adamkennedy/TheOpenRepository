#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract::Parser;
use Pod::Abstract::Path;
use Data::Dumper;

my $p = Pod::Abstract::Parser->new;
$p->parse_from_filehandle(\*STDIN) unless @ARGV;
print $p->root->text_ptree;

=head1 example expressions

 'head1/head2[/foo]/head3[/:paragraph =~ {wiggy}]'

Read as:

 head1 elements
  head2 elements in those
   only those contining a child "foo"
    head3 elements in those
     but only if there is the word "wiggy" in a child paragraph

 'head1/head2[/head3[/:paragraph =~ {wiggy}]]'

Read as
 
 head1 elements
  head2 elements in those
   only those with a head3 element where the head3 element includes a
   paragraph with the wordk "wiggy"

=cut

my $path = Pod::Abstract::Path->new(q|
head1/
 head2
  [/head3
   [/:paragraph =~ {wiggy}][!/:paragraph =~ {woo}]
  ]
|);
$path = Pod::Abstract::Path->new(q|//:paragraph[//:E =~ {gt}]|);
#    'head1/head2[/head3[/:paragraph =~ {wiggy}][!/:paragraph =~ {woo}]](0)'
#    'head1/head2[!/foo]/head3[/:paragraph =~ {wiggy}]'

# print Dumper([$path]);
my @nodes = $path->process($p->root->children);
my $c_nodes = @nodes;
print "Matched $c_nodes nodes\n";
foreach my $node (@nodes) {
    print "[--------------]\n";
    print $node->text_ptree;
}

foreach my $f (@ARGV) {
    $p = Pod::Abstract::Parser->new;
    $p->parse_from_file($f);
    print $p->root->text_ptree;
}
