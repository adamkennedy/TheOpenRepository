package Pod::Abstract;
use strict;
use warnings;

use Pod::Abstract::Node;
use Pod::Abstract::Path;
use Pod::Abstract::Parser;
use IO::String;

our $VERSION = '0.14';

=head1 NAME

Pod::Abstract - Abstract document tree for Perl POD documents

=head1 SYNOPSIS

 use Pod::Abstract;
 use Pod::Abstract::BuildNode qw(node);

 # Get all the first level headings, and put them in a verbatim block
 # at the start of the document
 my $pa = Pod::Abstract->load_filehandle(\*STDIN);
 my @headings = $pa->select('/head1@heading');
 my @headings_text = map { $_->pod } @headings;
 my $headings_node = node->verbatim(join "\n",@headings_text);

 $pa->unshift( node->cut );
 $pa->unshift( $headings_node );
 $pa->unshift( node->pod );

 print $pa->pod;

=head1 DESCRIPTION

POD::Abstract provides a means to load a POD (or POD compatible)
document without direct reference to it's syntax, and perform
manipulations on the abstract syntax tree.

This can be used to support additional features for POD, to format
output, to compile into alternative formats, etc.

=head2 PROCESSING MODEL

The intent with POD::Abstract is to provide a means to decorate a
parse tree, rather than manipulate text, as a means to add features
and functionality to POD based documenation systems.

If you wish to write modules that interact nicely with other
POD::Abstract modules, then you should provide a POD::Abstract -E<gt>
POD::Abstract translation. Leave any document element that your
program is not interested in directly untouched in the parse tree, and
if you have data that could be useful to other packages, decorate the
parse tree with that data even if you don't see any direct way to use
it in the output.

In this way, when you want one more feature for POD, rather than write
or fork a whole translator, a single inline "decorator" can be added.

=head2 EXAMPLE

Suppose you are frustrated by the verbose list syntax used by regular
POD. You might reasonably want to define a simplified list format for
your own use, except POD formatters won't support it.

With Pod::Abstract you can right an inline filter to convert:

 =begin list

 * item 1
 * item 2
 * item 3

 =end list

into:

 =over

 =item *

 item 1

 =item *

 item 2

 =item *

 item 3

 =back

This transformation can be simply performed on the document tree. If
your formatter does not use Pod::Abstract, you can simply pipe out POD
and use a regular formatter. If your formatter supports Pod::Abstract
though, then you can feed in the syntax tree directly without having
to re-serialise and parse the document.

=head2 POD SUPPORT

Pod::Abstract aims to support all POD rules defined in perlpodspec
(even the ones I don't like), except for those directly related to
formatting output, or which cannot be implemented generically.

=head1 COMPONENTS

Pod::Abstract is comprised of:

=over

=item *

The parser, which loads a document tree for you.

You should access this through C<Pod::Abstract>, not directly

=item *

The document tree, which is the root node you are given by the
parser. Calling B<pod> on the root node should always give you back
your original document.

See L<Pod::Abstract::Node>

=item *

L<Pod::Abstract::Path>, the node selection expression language. This
is generally called by doing C<<$node->select(PATH_EXP)>>.

=item *

The node builder, L<Pod::Abstract::BuildNode>

=back

=head1 METHODS

=cut


=head2 load_file

 my $pa = Pod::Abstract->load_file( FILENAME );

Read the POD document in the named file. Returns the root node of the
document.

=cut

sub load_file {
    my $class = shift;
    my $filename = shift;
    
    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_file($filename);
    $p->root->coalesce_body(":verbatim");
    $p->root->coalesce_body(":text");
    return $p->root;
}

=head2 load_filehandle

 my $pa = Pod::Abstract->load_file( FH );

Load a POD document from the provided filehandle reference. Returns
the root node of the document.

=cut

sub load_filehandle {
    my $class = shift;
    my $fh = shift;

    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_filehandle($fh);
    $p->root->coalesce_body(":verbatim");
    $p->root->coalesce_body(":text");
    return $p->root;
}

=head2 load_string

 my $pa = Pod::Abstract->load_string( STRING );

Loads a POD document from a scalar string value. Returns the root node
of the document.

=cut

sub load_string {
    my $class = shift;
    my $str = shift;
    
    my $fh = IO::String->new($str);
    return $class->load_filehandle($fh);
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
