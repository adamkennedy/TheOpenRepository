package Macropod::Parser::Includes::base;
use strict;
use warnings;
use Macropod::Util qw( dequote_list );


sub parse {
        my ($self,$doc,$class,$node) = @_;
        return unless $class eq 'base';
        my $imports = $node->find_first( 'PPI::Token::QuoteLike::Words' );
        my @classes = dequote_list( $imports );
        $doc->add( inherits =>  $_ => { } ) for @classes ;
        return 1;
}


1;

