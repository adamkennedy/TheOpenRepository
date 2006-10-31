package Kephra::Edit::Select;
$VERSION = '0.01';

# text selection

use strict;
use Wx qw( wxSTC_CMD_PARAUPEXTEND wxSTC_CMD_PARADOWNEXTEND );

sub _get_edit_panel { Kephra::App::EditPanel::_get() }

sub all      { &document }
sub document { _get_edit_panel()->SelectAll }
sub all_if_non {
	my $ep = _get_edit_panel();
	$ep->SelectAll if $ep->GetSelectionStart == $ep->GetSelectionEnd;
	my ($start, $end) = $ep->GetSelection;
	return $ep->GetTextRange( $start, $end );
}

sub to_block_begin{ _get_edit_panel()->CmdKeyExecute(wxSTC_CMD_PARAUPEXTEND)   }
sub to_block_end  { _get_edit_panel()->CmdKeyExecute(wxSTC_CMD_PARADOWNEXTEND) }

1;