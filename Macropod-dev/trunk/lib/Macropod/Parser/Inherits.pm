package Macropod::Parser::Inherits;
use strict;
use warnings;

require Macropod::Parser::Includes;


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

sub _inherits_Class__Accessor {
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
				&& $ele->child(2)->content =~ /^mk_accessor(?:s)?/;
		}
	);
	warn $package_calls;
	return unless $package_calls;

	foreach my $call ( @$package_calls  ) {

		#my $list = $call->find( 'PPI::Token::QuoteLike::Words' ) ;
		my $list = $call->find_first('PPI::Structure::List' );
		next unless $list;
		#warn Dumper $list;
	}

}


1;

