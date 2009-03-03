#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

ok( my $root = node->root, "Root node" );
ok( my $heading = node->head1('Test', "Heading 1" ));
ok( $root->nest($heading), "Nested heading" );
ok( $heading->push(
        node->paragraph("Test B<Para>")),
    "Added para",
    );
ok( my $list = node->over, "Over" );
ok( my $item = node->item('*') );
ok( $item->nest(
        node->paragraph("Test Item")),
    "Added item"
    );
ok( $list->nest($item), "Nested item" );
ok( $heading->push($list), "Added list" );

my $pod =
q|=head1 Test

Test B<Para>

=over

=item *

Test Item

=back

|;

is( $root->pod, $pod, "Generated correct Pod" );

1;
