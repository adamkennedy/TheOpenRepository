package Kephra::App::EventList;
$VERSION = '0.05';

# internal app events handling

use strict;
use Wx::Event qw(
	EVT_KEY_UP EVT_KEY_DOWN
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_CLOSE EVT_DROP_FILES EVT_MENU_OPEN
	EVT_STC_CHANGE EVT_STC_UPDATEUI
	EVT_STC_SAVEPOINTREACHED EVT_STC_SAVEPOINTLEFT
);
# EVT_STC_CHARADDED EVT_STC_MODIFIED

# get pointer to the event list
sub _get        { $Kephra::app{'eventlist'} }
sub _get_frozen { $Kephra::temp{'eventlist'} }


sub init {
	my $win = Kephra::App::Window::_get();
	my $ep  = Kephra::App::EditPanel::_get();

	# events for whole window
	EVT_CLOSE      ($win,  sub { trigger('app.close'); Kephra::quit() });
	EVT_DROP_FILES ($win,  \&Kephra::File::add_dropped);
	EVT_MENU_OPEN  ($win,  sub { trigger('menu.open') });

	# scintilla and editpanel events
	EVT_DROP_FILES ($ep,   \&Kephra::File::add_dropped); # override sci presets
	EVT_STC_CHANGE ($ep, -1, sub {
		my ( $ep, $event ) = @_;
		$Kephra::document{'current'}{'edit_pos'} = $ep->GetCurrentPos;
		trigger('document.text.change');
#print "change \n";
	});

	EVT_ENTER_WINDOW ($ep,   sub {
		Wx::Window::SetFocus( $ep ) unless $Kephra::temp{'dialog'}{'active'};
		trigger('editpanel.focus');
	});
	#EVT_SET_FOCUS           ($stc,    sub {});

	EVT_STC_UPDATEUI        ($ep, -1, sub {
		my ( $ep, $event) = @_;
		my ( $sel_beg, $sel_end ) = $ep->GetSelection;
		my $prev_selected = $Kephra::temp{'current_doc'}{'text_selected'};
		$Kephra::temp{'current_doc'}{'text_selected'} = $sel_beg != $sel_end;
		Kephra::App::EventList::trigger('document.text.select')
			if $Kephra::temp{'current_doc'}{'text_selected'} xor $prev_selected;
		Kephra::App::EventList::trigger('caret.move');
	});

	EVT_STC_SAVEPOINTREACHED($ep, -1, \&Kephra::File::savepoint_reached);
	EVT_STC_SAVEPOINTLEFT   ($ep, -1, \&Kephra::File::savepoint_left);
	#EVT_STC_MARGINCLICK     ($stc, -1, sub {Kephra::Dialog::msg_box($_[0], '')});
}


sub add_call{
	return until ref $_[2] eq 'CODE';
	$Kephra::app{'eventlist'}{ $_[0] }{ $_[1] } = $_[2];
}

sub trigger{
	my $list = _get();
	for my $event (@_){#print "event: $event \n";
		if (ref $list->{$event} eq 'HASH'){
			$_->() for values %{ $list->{$event} }
		}
	}
}

sub freeze{
	my $list = _get();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub freeze_all{
	my $list = _get();
	my $frozen = _get_frozen();
	for my $event (keys %$list ){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub thaw{
	my $list = _get();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub thaw_all{
	my $list = _get();
	my $frozen = _get_frozen();
	for my $event (keys %$frozen ){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub del_call{
	return until $_[1];
	my $list = _get();
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
}

sub delete_active{
	my $list = _get();
	delete $list->{ $_ } for keys %$list;
}

sub delete_frozen{
	my $frozen = _get_frozen();
	delete $frozen->{ $_ } for keys %$frozen;
}

sub delete_all { delete_active() ; delete_frozen() }

1;