#!/usr/bin/perl

use strict;
use warnings;

use Pod::Abstract::Parser;
use Pod::Abstract::Path;
use Pod::Abstract;
use Data::Dumper;

my $pa = Pod::Abstract->load_filehandle(\*STDIN);

=head1 example expressions

These currently work on Pod/Abstract.pm

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
   paragraph with the word "wiggy"

=cut

my $path = q|
/head1/
 head2
  [/head3
   [/:paragraph =~ {wiggy}][!/:paragraph =~ {woo}]
  ]
|;
#    '//:paragraph[//:E =~ {gt}]'
#    'head1/head2[/head3[/:paragraph =~ {wiggy}][!/:paragraph =~ {woo}]](0)'
#    'head1/head2[!/foo]/head3[/:paragraph =~ {wiggy}]'

print $pa->ptree;
my @nodes = $pa->select($path);
my $c_nodes = @nodes;
print "Matched $c_nodes nodes\n";
foreach my $node (@nodes) {
    print "[--------------]\n";
    print $node->ptree;
}

1;
