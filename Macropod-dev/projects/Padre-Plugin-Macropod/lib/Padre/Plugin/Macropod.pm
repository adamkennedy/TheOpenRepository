package Padre::Plugin::Macropod;
use strict;
use warnings;
use base qw( Padre::Plugin );

use Scalar::Util qw( blessed );
use vars qw( $VERSION $BUILD );
$BUILD = 'teapot';
$VERSION = '0.22';

warn __PACKAGE__ . "version $VERSION , build $BUILD";	

use Padre::Pod::Frame;
use Padre::Pod::Viewer;
use Padre::Documents;
use Macropod::Parser;
use Macropod::Processor;
use Padre::Wx::MacropodFrame;
use Padre::Task::Macropod;


sub padre_interfaces {
  'Padre::Plugin' => 0.22,
  'Padre::Document::Perl' => 0.22,
  'Padre::Pod::Frame'=>0.22,
}

sub plugin_enable {
  my ($self) = @_;
 eval {

    
    my $display = Padre::Pod::Frame->new();
    my $oldhelp = Padre->ide->wx->main_window->{help};
    my $oldhtml = $display->{html};
    warn $oldhtml->GetParent;
    
    my $newhtml = Padre::Wx::MacropodFrame->new($oldhtml->GetParent, -1);
    warn "REPLACE BY $newhtml";
    $display->{html} = $newhtml;
    $oldhtml->GetParent->GetSizer->Add( $newhtml, 1, Wx::wxGROW|Wx::wxALL, 5  );
    $oldhtml->Destroy;
    $display->Show();
    
    
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

warn __PACKAGE__ . " Failed to enable plugin: $@" if $@;

return $@ ? 1 : 0;

}

sub plugin_disable {
    my ($plugin) = @_;

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


