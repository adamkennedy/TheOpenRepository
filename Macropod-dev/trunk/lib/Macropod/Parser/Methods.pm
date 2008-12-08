package Macropod::Parser::Methods;
use strict;
use warnings;

use Carp qw( confess carp );
use Data::Dumper;



sub parse {
  my ($plugin,$doc) = @_;
  my $subs =  $doc->subs;
  return unless $subs;
  unless ('ARRAY' eq ref $subs ) {
    carp "Passed '$subs' not ARRAY";
    return;
  }
  
  foreach my $sub ( @$subs ) {
    # Has prototypes

	my $proto = $sub->find('PPI::Token::Prototype');
	my @proto;
	foreach my $p 
		( ('ARRAY' eq ref $proto) ? @$proto : ($proto) ) 
	{
		next unless $p;
		push @proto,$p->prototype;
	}
	
	my $subname = $sub->child(2);
    # Has attributes
    #my %attribs;
    
    # Looks like a method;
    
    $doc->add( 'method' ,
    	 $subname => { 
    	 	
    	 	#attributes=>\%attribs, 
    	 	(@proto) ? (prototype=>\@proto) :(),
    	 }
    );
  }
    

}
1

