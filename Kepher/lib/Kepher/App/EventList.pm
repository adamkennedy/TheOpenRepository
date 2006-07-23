package KEPHER::App::EventList;
$VERSION = '0.03';

# internal app events handling

use strict;
use Wx::Event qw(
	EVT_MENU_OPEN 
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW
	EVT_STC_CHANGE 
);
# EVT_STC_CHARADDED EVT_STC_MODIFIED

# get pointer to the event list
sub _get { $KEPHER::app{'eventlist'} }


sub init {
	my $win = KEPHER::App::Window::_get();
	my $ep  = KEPHER::App::EditPanel::_get();

	EVT_MENU_OPEN  ( $win,    sub { trigger('menu.open') });
	EVT_STC_CHANGE ( $ep, -1, sub {
		my ( $ep, $event ) = @_;
		$KEPHER::document{'current'}{'edit_pos'} = $ep->GetCurrentPos;
print "change \n";
		trigger('document.text.change');
	});
	EVT_ENTER_WINDOW ($ep,    sub {
		Wx::Window::SetFocus( $ep ) unless $KEPHER::internal{'dialog'}{'active'};
		trigger('editpanel.focus');
	});
}


sub add_call{
	return until ref $_[2] eq 'CODE';
	$KEPHER::app{'eventlist'}{ $_[0] }{ $_[1] } = $_[2];
}

sub trigger{
	my $list = _get();
	for my $event (@_){
#print "event: $event \n";
		if (ref $list->{$event} eq 'HASH'){
			$_->() for values %{ $list->{$event} }
		}
	}
}

sub freeze{
	my $list = _get();
	for my $event (@_){
		if (ref $list->{$event} eq 'HASH'){
			$KEPHER::internal{'eventlist'}{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub freeze_all{
	my $list = _get();
	for my $event (keys %$list ){
		if (ref $list->{$event} eq 'HASH'){
			$KEPHER::internal{'eventlist'}{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub thaw{
	my $list = _get();
	my $store = $KEPHER::internal{'eventlist'};
	for my $event (@_){
		if (ref $store->{$event} eq 'HASH'){
			$list->{$event} = $store->{$event};
			delete $store->{$event};
		}
	}
}

sub thaw_all{
	my $list = _get();
	my $store = $KEPHER::internal{'eventlist'};
	for my $event (keys %$store ){
		if (ref $store->{$event} eq 'HASH'){
			$list->{$event} = $store->{$event};
			delete $store->{$event};
		}
	}
}

sub del_call{
	return until $_[1];
	my $list = _get();
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
}

sub delete_all{
	my $list = _get();
	delete $list->{ $_ } for keys %$list;
}


1;