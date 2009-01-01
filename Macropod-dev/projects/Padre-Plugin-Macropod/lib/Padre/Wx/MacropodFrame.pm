package Padre::Wx::MacropodFrame;
use strict;
use warnings;

use base qw( Padre::Pod::Viewer );
use Scalar::Util qw( blessed );

sub display {
  my ($self,$ref) = @_;

  my $task = eval {
	    Padre::Task::Macropod->new( doc=>$ref, main_thread_only =>
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
