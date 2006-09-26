package Kephra::Edit::Convert;
$VERSION = '0.08';

use strict;
use Wx qw(wxSTC_CMD_UPPERCASE wxSTC_CMD_LOWERCASE wxSTC_CMD_WORDRIGHT);

# Convert
sub upper_case {
	my $ep = &Kephra::App::STC::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_non;
	$ep->CmdKeyExecute(wxSTC_CMD_UPPERCASE);
	&Kephra::Edit::_restore_positions;
}

sub lower_case {
	my $ep = &Kephra::App::STC::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_non;
	$ep->CmdKeyExecute(wxSTC_CMD_LOWERCASE);
	&Kephra::Edit::_restore_positions;
}

sub title_case {
	my $ep = &Kephra::App::STC::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_non;
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
	&Kephra::Edit::_restore_positions;
	$ep->EndUndoAction;
}

sub sentence_case {
	my $ep = &Kephra::App::STC::_get;
	my $line;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_non;
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
	&Kephra::Edit::_restore_positions;
	$ep->EndUndoAction;
}

sub spaces2tabs {
	Kephra::Edit::_save_positions();
	my $ep = &Kephra::App::STC::_get;
	my $space = " " x $Kephra::document{'current'}{'tab_size'};
	my $text = Kephra::Edit::_select_all_if_non();
	$text =~ s/$space/\t/g;
	$ep->BeginUndoAction();
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction();
	Kephra::Edit::_restore_positions();
}

sub tabs2spaces {
	Kephra::Edit::_save_positions();
	my $ep = &Kephra::App::STC::_get;
	my $space = " " x $Kephra::document{'current'}{'tab_size'};
	my $text = Kephra::Edit::_select_all_if_non();
	$text =~ s/\t/$space/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	Kephra::Edit::_restore_positions();
}

1;
