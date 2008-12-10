package Macropod::Parser::Includes::Exporter;
use strict;
use warnings;
use Carp qw( confess );
use Macropod::Util qw( dequote_list );


sub parse {
    my ($self,$doc,$class,$node) = @_;
    confess "Need a PPI document $doc" unless ref $doc->ppi eq 'PPI::Document';
    my $export_ok = $doc->ppi->find_first(
                sub {
                        my $node = $_[1];
                        return unless $node->isa('PPI::Statement');
                        my $sym = $node->find_first('PPI::Token::Symbol') ;
                        return unless $sym;
                        return 1 if $sym->content eq '@EXPORT_OK';
                        return 1 if $sym->content eq '@EXPORT';
                }
    );
    return unless $export_ok;
    my $words = $export_ok->find_first( 'PPI::Token::QuoteLike::Words' );
    my @symbols =  dequote_list( $words );
    my %sym;
    @sym{@symbols} = @symbols;
    $doc->add( exports =>  symbols => \%sym   );

    return 1;

}


1;

