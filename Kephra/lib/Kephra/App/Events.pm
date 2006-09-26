package Kephra::App::Events;
$VERSION = '0.35';

use strict;
use Wx qw( wxSTC_CMD_NEWLINE );
use Wx::Event qw(
	EVT_TEXT_ENTER
	EVT_LEFT_UP EVT_LEFT_DOWN EVT_MIDDLE_UP EVT_RIGHT_DOWN EVT_MOUSEWHEEL
	EVT_KEY_DOWN EVT_KEY_UP
EVT_STC_SAVEPOINTREACHED EVT_STC_SAVEPOINTLEFT EVT_STC_UPDATEUI EVT_STC_MARGINCLICK
	EVT_SET_FOCUS EVT_ENTER_WINDOW EVT_LEAVE_WINDOW
	EVT_PAINT EVT_ERASE_BACKGROUND EVT_CLOSE  EVT_DROP_FILES
);

##########################
##########################
sub set_table {
 my $h      = Kephra::App::Window::_get();
 my $stc    = Kephra::App::EditPanel::_get();

# events for whole window
	EVT_CLOSE               ($h,       \&Kephra::quit);
	EVT_DROP_FILES          ($h,       \&Kephra::File::add_dropped);

# scintilla and editpanel events
	EVT_DROP_FILES          ($stc,     \&Kephra::File::add_dropped); # override sci presets
	#EVT_SET_FOCUS           ($stc,    sub {});
	EVT_STC_UPDATEUI        ($stc, -1, sub {
		my ( $ep, $event) = @_;
		my ( $sel_beg, $sel_end ) = $ep->GetSelection;
		my $prev_selected = $Kephra::temp{'current_doc'}{'text_selected'};
		$Kephra::temp{'current_doc'}{'text_selected'} = $sel_beg != $sel_end;
		Kephra::App::EventList::trigger('document.text.select')
			if $Kephra::temp{'current_doc'}{'text_selected'} xor $prev_selected;
		Kephra::App::EventList::trigger('caret.move');
	});
	EVT_STC_SAVEPOINTREACHED($stc, -1, \&Kephra::File::savepoint_reached);
	EVT_STC_SAVEPOINTLEFT   ($stc, -1, \&Kephra::File::savepoint_left);
	#EVT_STC_MARGINCLICK     ($stc, -1, sub {Kephra::Dialog::msg_box($_[0], '')});

	# keyboard commands
	#EVT_KEY_UP              ($stc,     sub {} );
	EVT_KEY_DOWN            ($stc,     sub {
		my ($ep, $event) = @_;
		my $map = $Kephra::app{editpanel}{keymap};
		my $key = $event->GetKeyCode + 
			1000 * ($event->ShiftDown + $event->ControlDown*2 + $event->AltDown*4);
	
		if (ref $map->[$key] eq 'CODE'){
			$map->[$key]();
		} elsif ($key ==  13) { # Enter
			if ($Kephra::config{'editpanel'}{'auto'}{'brace'}{'indention'}) {
				my $pos  = $ep->GetCurrentPos - 1;
				my $char = $ep->GetCharAt($pos);
				if    ($char == 123) {Kephra::Edit::blockindent_open($pos) ; return;}
				elsif ($char == 125) {Kephra::Edit::blockindent_close($pos); return;}
			}
			$Kephra::config{'editpanel'}{'auto'}{'indention'}
				? Kephra::Edit::autoindent()
				: $ep->CmdKeyExecute(wxSTC_CMD_NEWLINE) ;
		} else { $event->Skip }
		#Kephra::Dialog::msg_box(undef,$key,""); #Kephra::App::Visual::status_msg();
		#SCI_SETSELECTIONMODE
		#($key == 350){use Kephra::Ext::Perl::Syntax;  Kephra::Ext::Perl::Syntax::check()};
	});
	# mouse clicks on editpanel
	#EVT_LEFT_UP   ($stc, sub {}); #EVT_LEFT_DOWN ($stc, sub {});
}

1;
