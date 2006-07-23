package PCE::Edit::Convert;
$VERSION = '0.08';

use strict;
use Wx qw(wxSTC_CMD_UPPERCASE wxSTC_CMD_LOWERCASE wxSTC_CMD_WORDRIGHT);

# Convert
sub upper_case {
	my $ep = &PCE::App::STC::_get;
	&PCE::Edit::_save_positions;
	&PCE::Edit::_select_all_if_non;
	$ep->CmdKeyExecute(wxSTC_CMD_UPPERCASE);
	&PCE::Edit::_restore_positions;
}

sub lower_case {
	my $ep = &PCE::App::STC::_get;
	&PCE::Edit::_save_positions;
	&PCE::Edit::_select_all_if_non;
	$ep->CmdKeyExecute(wxSTC_CMD_LOWERCASE);
	&PCE::Edit::_restore_positions;
}

sub title_case {
	my $ep = &PCE::App::STC::_get;
	&PCE::Edit::_save_positions;
	&PCE::Edit::_select_all_if_non;
	my ($sel_end, $pos) = ($ep->GetSelectionEnd, 0);
	$ep->BeginUndoAction;
	$ep->SetCurrentPos( $ep->GetSelectionStart - 1 );
	while () {
		$ep->CmdKeyExecute(wxSTC_CMD_WORDRIGHT);
		$pos = $ep->GetCurrentPos;
		last if $sel_end <= $pos;
		$ep->SetSelection( $pos, $pos + 1 );
		$ep->CmdKeyExecute(wxSTC_CMD_UPPERCASE);
	}
	&PCE::Edit::_restore_positions;
	$ep->EndUndoAction;
}

sub sentence_case {
	my $ep = &PCE::App::STC::_get;
	my $line;
	&PCE::Edit::_save_positions;
	&PCE::Edit::_select_all_if_non;
	my ($sel_end, $pos) = ($ep->GetSelectionEnd, 0);
	$ep->BeginUndoAction;
	$ep->SetCurrentPos( $ep->GetSelectionStart() - 1 );
	while () {
		$ep->CmdKeyExecute(wxSTC_CMD_WORDRIGHT);
		$pos  = $ep->GetCurrentPos;
		$line = $ep->LineFromPosition($pos);
		if ($pos == $ep->GetLineEndPosition( $ep->LineFromPosition($pos) )) {
			$ep->CmdKeyExecute(wxSTC_CMD_WORDRIGHT);
			$pos = $ep->GetCurrentPos;
		}
		last if $sel_end <= $pos;
		$ep->SetSelection( $pos, $pos + 1 );
		$ep->CmdKeyExecute(wxSTC_CMD_UPPERCASE);
		$ep->SetCurrentPos( $pos + 1 );
		$ep->SearchAnchor;
		last if $ep->SearchNext( 0, "." ) == -1 ;
	}
	&PCE::Edit::_restore_positions;
	$ep->EndUndoAction;
}

sub spaces2tabs {
	PCE::Edit::_save_positions();
	my $ep = &PCE::App::STC::_get;
	my $space = " " x $PCE::document{'current'}{'tab_size'};
	my $text = PCE::Edit::_select_all_if_non();
	$text =~ s/$space/\t/g;
	$ep->BeginUndoAction();
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction();
	PCE::Edit::_restore_positions();
}

sub tabs2spaces {
	PCE::Edit::_save_positions();
	my $ep = &PCE::App::STC::_get;
	my $space = " " x $PCE::document{'current'}{'tab_size'};
	my $text = PCE::Edit::_select_all_if_non();
	$text =~ s/\t/$space/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	PCE::Edit::_restore_positions();
}

1;
