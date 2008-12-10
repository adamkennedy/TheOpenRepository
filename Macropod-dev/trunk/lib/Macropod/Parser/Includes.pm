package Macropod::Parser::Includes;
use strict;
use warnings;
use Carp qw( confess carp cluck);
use Data::Dumper;
use Macropod::Util qw( dequote dequote_list ppi_find_list );
use Module::Pluggable
        require     => 1,
        search_path => 'Macropod::Parser::Includes',
        only        => qr/Macropod::Parser::Includes::(\w+)$/; 


sub parse {
	my ($self,$doc) = @_;
	my $uses_packages =  $doc->includes;
	return unless $uses_packages;
    unless ('ARRAY' eq ref $uses_packages ) {
    	warn "Passed '$uses_packages' not ARRAY";
        $uses_packages = [ $doc->includes ];
    }
	foreach my $used ( @$uses_packages ) {
		# naive , most of the time 'use Package' but not always
		#warn "Undefined " . Dumper $used;
		my $class = $used->child(2); 
		#warn $doc->title . " uses '$class'";
		if ( $class =~ /hide/ ) {
			warn $doc->source . 
				' hiding from PAUSE ?! Unhandled by' . __PACKAGE__;
			next;
		}
		
		#my $hook = "_uses_" . $class->content;
		#$hook =~ tr/:/_/;

		#if  ( $self->can( $hook ) ) {
		#warn "Try to hook $hook";
		#	$self->$hook( $doc , $used );	
		#}

                my $skip_default = 0;
                foreach my $plugin ( $self->plugins ) {
                    $skip_default++
                      if ($plugin->parse( $doc, $class->content, $used ));
                }
		
		unless ( $skip_default ) {
		    if( $used->find_any( 'PPI::Token::QuoteLike::Words' ) ) {
			$self->_uses_imports( $doc , $class->content, $used );
		    }
 		    $doc->add( requires => $class->content => {});
                }
	}	

}





sub _uses_imports {
	my ($self,$doc,$class,$statement) = @_;
	#warn Dumper $statement;
	my $list = $statement->find('PPI::Token::QuoteLike::Words');
	#warn "IMPORTS: " , Dumper $list->[0]->content;
	my %meta;
	my $str = $list->[0]->content;
	my @functions  =  dequote_list( $str ); # FIXME not all are functions
	@meta{@functions} = @functions;
	#confess ;
	$doc->add( imports => $class => { functions => \%meta } ) ;
}

use Data::Dumper;



sub _uses_base {
	my ($self,$doc,$node) = @_;
	my $imports = $node->find_first( 'PPI::Token::QuoteLike::Words' );
	my @classes = dequote_list( $imports );
	$doc->add( inherits =>  $_ => { } ) for @classes ;
}

sub _uses_Exporter {
	my ($self,$doc,$node) = @_;
	confess "Need a PPI document $doc" unless ref $doc->ppi eq 'PPI::Document';
	carp "Exporter";
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

}

sub _uses_vars {
    my ($self,$doc,$node) = @_;
    my $imports = $node->find(  ppi_find_list  );
    my @symbols;
    foreach my $word ( @$imports ) {
        my @terms = dequote_list( $word );
        push @symbols, @terms;
    }
    $doc->mk_accessors( 'variables' );
    $doc->add( 'variables' => $_ => {} ) for @symbols;

#	warn "use vars uncaught";
}

sub _uses_constant {
#	warn "use constant uncaught";
}

sub _uses_Test__More {};


1;

