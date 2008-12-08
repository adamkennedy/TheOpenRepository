package Macropod::Parser::Includes;
use strict;
use warnings;
use Carp qw( confess carp );
use Data::Dumper;

#sub _dequote($) {
#	Macropod::Parser::_dequote( shift )
#}
sub run_after {''};

sub dequote($) {
 	my $s = shift;
 	my $begin = substr( $s, 0, 3 );
 	my $end = substr( $s,-1,1 );
 	my ($term) = grep { $_ eq $end} split //,$begin;
 	my $cut_in = index( $s,$term,0 ) + 1;
 	confess "Cannot find quoter" unless $cut_in;
 	my $dq = substr( $s , $cut_in  );
 	chop $dq;
 	carp "Failed '$s'" unless ( $dq || $s eq $dq );
 	
 	return split /\s+/ ,$dq;
}

sub parse {
	my ($self,$doc) = @_;
	my $uses_packages =  $doc->includes;
	return unless $uses_packages;
    unless ('ARRAY' eq ref $uses_packages ) {
    	carp "Passed '$uses_packages' not ARRAY";
    	return;
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
		
		my $hook = "_uses_" . $class->content;
		$hook =~ tr/:/_/;

		if  ( $self->can( $hook ) ) {
		#warn "Try to hook $hook";
			$self->$hook( $doc , $used );	
		}
		elsif( $used->find_any( 'PPI::Token::QuoteLike::Words' ) ) {
			$self->_uses_imports( $doc , $class->content, $used );
		}
		else {
			#warn "Add requires for " . $class->content;
			$doc->add( requires => $class->content => {});
			#warn "Uncaught include of " . $class->content;
			#warn PPI::Dumper->new( $used )->print;
		}
		#$self->_chase( $class->content );
	}	

	$uses_packages;
}





sub _uses_imports {
	my ($self,$doc,$class,$statement) = @_;
	#warn Dumper $statement;
	my $list = $statement->find('PPI::Token::QuoteLike::Words');
	#warn "IMPORTS: " , Dumper $list->[0]->content;
	my %meta;
	my $str = $list->[0]->content;
	my @functions  =  dequote $str; # FIXME not all are functions
	@meta{@functions} = @functions;
	#confess ;
	$doc->add( imports => $class => { functions => \%meta } ) ;
}

use Data::Dumper;



sub _uses_base {
	my ($self,$doc,$node) = @_;
	#warn "Uses BASE";
	my $imports = $node->find_first( 'PPI::Token::QuoteLike::Words' );

	my @classes = dequote $imports;
		#split /(\s|q(r|x|q|w).)/, $imports;
#		 $imports =~ /([+-:\w]+)+/g;
#	grep !/^q(r|q|w)/ ,
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
 	my @symbols =  dequote $words;
 	my %sym;
 	@sym{@symbols} = @symbols;
	$doc->add( exports =>  symbols => \%sym   );

}

sub _uses_vars {
#	warn "use vars uncaught";
}

sub _uses_constant {
#	warn "use constant uncaught";
}

sub _uses_Test__More {};


1;

