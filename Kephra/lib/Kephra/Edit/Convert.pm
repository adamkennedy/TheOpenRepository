package Kephra::Edit::Convert;
$VERSION = '0.08';

use strict;
use Wx qw(wxSTC_CMD_UPPERCASE wxSTC_CMD_LOWERCASE wxSTC_CMD_WORDRIGHT);

# Convert
sub upper_case {
	my $ep = &Kephra::App::EditPanel::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_none;
	$ep->CmdKeyExecute(wxSTC_CMD_UPPERCASE);
	&Kephra::Edit::_restore_positions;
}

sub lower_case {
	my $ep = &Kephra::App::EditPanel::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_none;
	$ep->CmdKeyExecute(wxSTC_CMD_LOWERCASE);
	&Kephra::Edit::_restore_positions;
}

sub title_case {
	my $ep = &Kephra::App::EditPanel::_get;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_none;
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
	my $ep = &Kephra::App::EditPanel::_get;
	my $line;
	&Kephra::Edit::_save_positions;
	&Kephra::Edit::_select_all_if_none;
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
	my $ep = &Kephra::App::EditPanel::_get;
	my $space = " " x $Kephra::document{'current'}{'tab_size'};
	my $text = Kephra::Edit::_select_all_if_none();
	$text =~ s/$space/\t/g;
	$ep->BeginUndoAction();
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction();
	Kephra::Edit::_restore_positions();
}

sub tabs2spaces {
	Kephra::Edit::_save_positions();
	my $ep = &Kephra::App::EditPanel::_get;
	my $space = " " x $Kephra::document{'current'}{'tab_size'};
	my $text = Kephra::Edit::_select_all_if_none();
	$text =~ s/\t/$space/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	Kephra::Edit::_restore_positions();
}

sub indent2tabs   { _indention(1) }
sub indent2spaces { _indention(0) }
sub _indention {
	my $use_tab = shift;
	my $ep = Kephra::App::EditPanel::_get();
	my ($begin, $end) = $ep->GetSelection;
	my $indention = $ep->GetUseTabs;
	my $i;
	$ep->SetUseTabs($use_tab);
	$ep->BeginUndoAction();
	for ($ep->LineFromPosition($begin) .. $ep->LineFromPosition($end)) {
		$i = $ep->GetLineIndentation($_);
		$ep->SetLineIndentation( $_, $i + 1 );
		$ep->SetLineIndentation( $_, $i );
	}
	$ep->EndUndoAction;
	$ep->SetUseTabs($indention);
}

1;
