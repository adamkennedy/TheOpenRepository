package Macropod::Parser::Includes::vars;

use strict;
use warnings;
use base qw( Macropod::Parser::Plugin );
use Macropod::Util qw( ppi_find_list dequote_list );



sub parse {
    my ($self,$doc,$class,$node) = @_;
    return 0 unless $class eq 'vars';

    my $imports = $node->find(  ppi_find_list  );
    my @symbols;
    foreach my $word ( @$imports ) {
        my @terms = dequote_list( $word );
        push @symbols, @terms;
    }
    $doc->mk_accessors( 'variables' );
    $doc->add( 'variables' => $_ => {} ) for @symbols;
   
    return 1;

}


1;
