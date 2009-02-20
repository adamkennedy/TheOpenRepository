package Pod::Abstract;
use strict;
use warnings;

use Pod::Abstract::Node;
use Pod::Abstract::Path;
use Pod::Abstract::Parser;

=pod

=head1 NAME

POD::Abstract - Abstract document tree and processing model for Perl
POD documents

=head1 SYNOPSIS

 use POD::Abstract;
 
 my $pa = POD::Abstract->load_file($file);
 my @headings = $pa->select("/head1");
 my $toc_text = map { $_->name . \n" } @headings;
 my $toc = POD::Abstract::Verbatim->new($toc_text);
 $pa->insert_before( 
    POD::Abstract::Heading->new("head1", "CONTENTS"),
    $toc );
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
if you have data that could be useful to other packages, decorate with
the parse tree with that data even if you don't see any direct way to
use it in the output.

For example, if you have written a module to number the sections of
POD documents with multipart numbers, these numbers can be picked up
by the simple table of contents module in the synopsis above.

In this way, when you want one more feature for POD, rather than write
or fork a whole translator, a single inline "decorator" can be added.

=cut

=head2 blah

=target

=head3

wiggy wiggy

target

=head2

=head3

wiggy wiggy

woo

=cut

sub load_file {
    my $class = shift;
    my $filename = shift;
    
    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_file($filename);
    return $p->root;
}

sub load_filehandle {
    my $class = shift;
    my $fh = shift;

    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_filehandle($fh);
    return $p->root;
}

1;
