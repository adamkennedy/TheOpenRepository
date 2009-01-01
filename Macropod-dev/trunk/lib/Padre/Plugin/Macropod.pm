package Padre::Macropod::Task;
use strict;
use warnings; 

use Carp qw( confess );
use Scalar::Util qw( blessed );
use base 'Padre::Task';
use Padre::Pod2HTML;
#our $EV_OUTPUT: shared = Wx::NewEventType();




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




package Padre::Macropod::Viewer;
use strict;
use warnings;

use base qw( Padre::Pod::Viewer );
use Scalar::Util qw( blessed );

sub display {
  my ($self,$ref) = @_;

  my $task = eval {
	    Padre::Macropod::Task->new( doc=>$ref, main_thread_only =>
		sub { $self->collect(@_);  } 
	);
	  };
  if ( $@ ) { warn $@ ; return };
	  
  $task->schedule;
  
  
}
  
sub collect {
    my ($self,$html) = @_;
    #warn "Collecting $html";
    $self->SetPage( $html );    
    $self->SetFocus;
    $self->Show(1);
}



sub macropod_currentdoc {
	my ($self) = shift;
	my $doc = Padre::Documents->current;
	warn "Current doc $doc";
	$self->display( \$doc->text_get );


};

1;


package Padre::Plugin::Macropod;
use 5.008;
use strict;
use warnings;
use base qw( Padre::Plugin );

use Scalar::Util qw( blessed );

#use lib qw( /home/smee/dev/tmp/Macropod-dev/trunk/lib );
use vars qw( $VERSION $BUILD );
$BUILD = 'cat';
$VERSION = '0.22';

warn __PACKAGE__ . "version $VERSION , build $BUILD";	

use Padre::Pod::Frame;
use Padre::Pod::Viewer;
use Padre::Documents;
use Macropod::Parser;
use Macropod::Processor;


sub padre_interfaces {
  'Padre::Plugin' => 0.20,
  'Padre::Document::Perl' => 0.20,
  'Padre::Pod::Frame'=>0.20,
}

sub plugin_enable {
  my ($self) = @_;
 eval {

    #require Padre::Macropod::Viewer;
    #require Padre::Macropod::Task;
    
    my $display = Padre::Pod::Frame->new();
    my $oldhelp = Padre->ide->wx->main_window->{help};
    my $oldhtml = $display->{html};
    warn $oldhtml->GetParent;
    
    my $newhtml = Padre::Macropod::Viewer->new($oldhtml->GetParent, -1);
    $display->{html} = $newhtml;
    $oldhtml->GetParent->GetSizer->Add( $newhtml, 1, Wx::wxGROW|Wx::wxALL, 5  );
    $oldhtml->Destroy;
    #$display->Show();
    
    
 if ( $oldhelp ) {
    warn __PACKAGE__ . " enabled - hijacking help" . $oldhelp;
    $self->{oldhelp} = $oldhelp;
    $oldhelp->Hide();
 }

 $display->SetFocus;
 $display->SetTitle( 'Macropod Podviewer' );
 
 $self->{help} = $display;
 Padre->ide->wx->main_window->{help} = $display;
};

warn $@ if @$;

return $@ ? 1 : 0;

}

sub plugin_disable {
	my ($plugin) = @_;

    require Class::Unload;
    
	if ( exists $plugin->{oldhelp} ) {
	    my $oldhelp = $plugin->{oldhelp};
	    my $help = $plugin->{help};
	    $help->Hide;
	    $help->Destroy;
	    warn __PACKAGE__ . " restoring $oldhelp";
	    Padre->ide->wx->main_window->{help} = $oldhelp;
	}
	else {
	    Padre->ide->wx->main_window->{help} = undef;
	}
   Class::Unload->unload( __PACKAGE__ . '::Task' );
   Class::Unload->unload( __PACKAGE__ . '::Viewer' );

}

sub plugin_name {
	return 'Macropod';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		 'Current Doc' => sub { $self->{help}{html}->macropod_currentdoc },
		 'About' => sub { $self->about },
		 ,
	];
}


sub about {
        my ($self) = @_;
        my $about = Wx::AboutDialogInfo->new;
        $about->SetName( $self->plugin_name );
        $about->SetDescription( <<"END_MESSAGE" );
Macropod hijacks the Padre POD Viewer , replacing it
with a Macropod equivalent. 

version $VERSION , build $BUILD

See Macropod for more details
http://svn.ali.as/cpan/trunk/Macropod-dev/trunk

END_MESSAGE

	# Show the About dialog
	Wx::AboutBox( $about );     
}

1;


