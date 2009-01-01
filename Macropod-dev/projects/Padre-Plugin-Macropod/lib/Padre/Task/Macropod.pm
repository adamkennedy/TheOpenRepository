package Padre::Task::Macropod;
use strict;
use warnings; 

use Carp qw( confess );
use Scalar::Util qw( blessed );
use base 'Padre::Task';
use Padre::Pod2HTML;



#sub prepare {
#    my $self = shift;
#    my $padre = Padre->ide->wx->main_window;
#    Wx::Event::EVT_COMMAND($main, -1, $EV_OUTPUT, \&display_document);	
#    return;
#    	
#}
{
my  $parser = Macropod::Parser->new();
#$parser->init_cache;	
sub run {
    my $self = shift;
    my $ref = $self->{doc};
    my $doc;
eval {
  if ( ref $ref eq 'SCALAR' ) {
	  warn "Parsing SCALAR";
    $doc = $parser->parse_text( $ref );
  }
  elsif ( blessed $ref && $ref->isa('Padre::Document') ) {
	warn "Parsing Padre::Document";
	$doc = $parser->parse_text( $ref->text_get);
  }
  else {
    my $path = Padre::Pod::Viewer->module_to_path( $ref );
    warn "Parsing resolved '$ref' to $path ";
    $doc = $parser->parse_file( $path );
  }
};

if ($@ ) {
  warn "FAILED PARSE $@";
  return;	
}
  unless ( defined $doc ) {
	 warn "Could not parse $ref " ;
	 return;
  }
  
  my $html = $self->inflate( $doc );
  $self->{html} = $html;
delete $self->{doc};

  #$self->post_event( $EV_OUTPUT , \$html );
  return 1;
    
	
}

}

sub inflate {
	my ($self,$doc) = @_;
	my $pod;
	eval {
		my $processor= Macropod::Processor->new();
		$pod     = $processor->process( $doc );

	};
	if ($@) {
		    warn "Failed to inflate $doc , $@";
		    return;
	}
	
#	my $html = eval { Padre::Pod2HTML->pod2html( $$pod ) };
#	warn "GOT HTML $html";
#	if ( $@ ) {
#		    warn "INFLATE FAIL $@";
#		    return;
#	}
	
	# yuk yuk yuk
	open ( FILEOUT, '>' , '/tmp/padre.macropod' );
	print FILEOUT $$pod;
	close FILEOUT;
	my $view = Padre::Pod::Viewer::POD->new;
	$view->start_html;
	$view->parse_from_file('/tmp/padre.macropod');
	my $html = $view->get_html;
	return $html;
}


sub finish {
    my ($self) = @_;
    $self->{main_thread_only}->( $self->{html} );
    return 1;
}
1;



