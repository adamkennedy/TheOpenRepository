package Padre::Plugin::Macropod;
use 5.008;
use strict;
use warnings;
use base qw( Padre::Plugin );

use Scalar::Util qw( blessed );

use Padre::Pod::Frame;
use Padre::Pod::Viewer;
use Padre::Documents;
use Macropod::Parser;
use Macropod::Processor;

our $VERSION = '0.22';

sub padre_interfaces {
  'Padre::Plugin' => 0.20,
  'Padre::Document::Perl' => 0.20,
  'Padre::Pod::Frame'=>0.20,
}

sub plugin_enable {
  my ($self) = @_;
 eval {

    require Macropod::Parser;
    require Macropod::Processor;
 
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

warn $@ if $@;

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
   #Class::Unload->unload( "Macropod::Parser" );
   # Class::Unload->unload( "Macropod::Processor" );

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

See Macropod for more details
http://svn.ali.as/cpan/trunk/Macropod-dev/trunk

END_MESSAGE

	# Show the About dialog
	Wx::AboutBox( $about );     
}

1;





package Padre::Macropod::Viewer;
use strict;
use warnings;

use base qw( Padre::Pod::Viewer );
use Scalar::Util qw( blessed );
our  $parser = Macropod::Parser->new();
#$parser->init_cache;

sub display {
  my ($self,$ref) = @_;
  my ($doc);
  if ( ref $ref eq 'SCALAR' ) {
	  warn "Parsing SCALAR";
    $doc = $parser->parse_text( $ref );
  }
    elsif ( blessed $ref && $ref->isa('Padre::Document') ) {
	warn "Parsing Padre::Document";
	$doc = $parser->parse_text( \$ref->{original_content} );
  }
  else {
    my $path = $self->module_to_path( $ref );
    warn "Parsing resolved '$ref' to $path ";
    $doc = $parser->parse_file( $path );
  }
  
  unless ( defined $doc ) {
	 warn "Could not parse $ref " ;
	 return;
  }	
  my $html = $self->inflate( $doc );

    $self->SetPage( $html );
    #$self->SetTitle( 'Macropod : ' . $doc->title );
$self->SetFocus;
$self->Show(1);
  

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
	#warn $$pod;
	
	open ( FILEOUT, '>' , '/tmp/padre.macropod' );
	print FILEOUT $$pod;
	close FILEOUT;
	my $view = Padre::Pod::Viewer::POD->new;
	$view->start_html;
	$view->parse_from_file('/tmp/padre.macropod');
	my $html = $view->get_html;
	return $html;
}

sub macropod_currentdoc {
	my ($self) = shift;
	my $doc = Padre::Documents->current;
	$self->display( $doc );


};

sub _setup_podviewer {
   my ($self) = @_;
   $self->SUPER::_setup_podviewer();
   my $old = $self->{html};
   my $new = Padre::Macropod::Viewer->new( $old->GetParent, -1 );
  
}



1;


