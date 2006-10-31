package Kephra::App::Events;
$VERSION = '0.35';

use strict;
use Wx qw( wxSTC_CMD_NEWLINE );
use Wx::Event qw(EVT_KEY_DOWN);

sub set_table {
 my $stc    = Kephra::App::EditPanel::_get();

	EVT_KEY_DOWN  ($stc,     sub {
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
}

1;
