package Macropod::Parser::Inherits;
use strict;
use warnings;
use Macropod::Util qw( dequote_list ppi_find_list );
use base qw( Macropod::Parser::Plugin );

# force Module::Pluggable to load this first?
require Macropod::Parser::Includes;

use Data::Dumper;

sub parse {
	my ($class,$doc) = @_;
	my $inherits =  $doc->inherits;
	#warn $inherits;
	while ( my ($classname,$meta) = each %$inherits ) {

		my $hook = "_inherits_" . $classname;
		$hook =~ tr/:/_/;
		#warn "testing '$hook'";
		if  ( $class->can( $hook ) ) {
			$class->$hook( $doc , $classname );	
		}
	}	


}

sub __inherits_Class__Accessor {
	my ($class,$doc) = @_;
	my $package_calls = $doc->{ppi}->find(
		sub { 
			my ($doc,$ele) = @_;
			return
				$ele->isa( 'PPI::Statement' )
				&& $ele->child(0)
				&& $ele->child(0)->isa( 'PPI::Token::Word' )
				&& $ele->child(0)->content eq '__PACKAGE__'
				&& $ele->child(1)
				&& $ele->child(1)->content eq '->'
				&& $ele->child(2)
				&& $ele->child(2)->content =~ /^(mk_accessors|mk_ro_accessors)?/;
		}
	);
	warn Dumper $package_calls;
	return unless $package_calls;
        $doc->mk_accessors( 'accessors' ); # the irony..
	foreach my $call ( @$package_calls  ) {

		#my $list = $call->find( 'PPI::Token::QuoteLike::Words' ) ;
		my $list = $call->find_first( ppi_find_list );
                confess $list->content;
		my @accessors = dequote_list( $list );
		$doc->add( accessors => $_ => {} ) for @accessors; 
	}

}


1;

