package Kephra::Edit;
$VERSION = '0.30';

# edit menu basic calls and internals for editing

use strict;
use Wx qw(:stc);    #Kephra::Dialog::msg_box(undef,'',"");
use Wx qw(
	wxSTC_CMD_NEWLINE wxSTC_CMD_LINECUT wxSTC_CMD_LINEDELETE wxSTC_CMD_DELLINELEFT
	wxSTC_CMD_DELLINERIGHT wxSTC_CMD_UPPERCASE wxSTC_CMD_LOWERCASE
	wxSTC_CMD_LINETRANSPOSE wxSTC_CMD_LINECOPY wxSTC_CMD_WORDLEFT
	wxSTC_CMD_WORDRIGHT wxSTC_FIND_WORDSTART wxSTC_CMD_LINEEND
	wxSTC_CMD_DELETEBACK wxSTC_CMD_PASTE
	wxSTC_MARK_CIRCLE wxSTC_MARK_ARROW wxSTC_MARK_MINUS
	wxCANCEL);

#
# internal helper function
#
sub _get_panel { Kephra::App::EditPanel::_get() }
sub _keep_focus{ Wx::Window::SetFocus( _get_panel() ) }

sub _let_caret_visible {
	my $ep = Kephra::App::EditPanel::_get();
	my ($selstart, $selend) = $ep->GetSelection;
	my $los = $ep->LinesOnScreen;
	if ( $selstart == $selend ) {
		$ep->ScrollToLine($ep->GetCurrentLine - ( $los / 2 ))
			unless $ep->GetCaretLineVisible;
	} else {
		my $startline = $ep->LineFromPosition($selstart);
		my $endline = $ep->LineFromPosition($selend);
		$ep->ScrollToLine( $startline - (($los - $endline - $startline) / 2) )
			unless $ep->GetLineVisible($startline)
			and $ep->GetLineVisible($endline);
	}
	$ep->EnsureCaretVisible;
}

sub _center_caret{
 my $ep = Kephra::App::EditPanel::_get();
	$ep->ScrollToLine($ep->GetCurrentLine - ( $ep->LinesOnScreen / 2 ));
	$ep->EnsureCaretVisible;
}

#Kephra::App::EditPanel::_get()->GotoPos(shift);
sub _goto_pos {
	my $pos = shift;
	my $ep  = Kephra::App::EditPanel::_get();
	my $max = $ep->GetLength;
	my $fvl = $ep->GetFirstVisibleLine;
	my $visible = $ep->GetLineVisible( $ep->LineFromPosition($pos) );

	$pos = 0 unless $pos or $pos < 0;
	$pos = $max if $pos > $max;
	$ep->SetCurrentPos($pos);
	$ep->SetSelection ($pos, $pos);
	$ep->SearchAnchor;
	_center_caret();
	#$visible ? $ep->ScrollToLine($fvl) : _center_caret();
	$ep->EnsureCaretVisible;
	#_keep_focus();
}

sub _save_positions {
	my $ep = Kephra::App::EditPanel::_get();
	my %pos;
	$pos{'document'}  = &Kephra::Document::_get_current_nr;
	$pos{'pos'}       = $ep->GetCurrentPos;
	$pos{'line'}      = $ep->GetCurrentLine;
	$pos{'col'}       = $ep->GetColumn( $pos{'pos'} );
	$pos{'sel_begin'} = $ep->GetSelectionStart;
	$pos{'sel_end'}   = $ep->GetSelectionEnd;
	push @{ $Kephra::temp{'edit'}{'caret'}{'positions'} }, \%pos;
}

sub _restore_positions {
	my $ep = Kephra::App::EditPanel::_get();
	my %pos      = %{ pop @{ $Kephra::temp{'edit'}{'caret'}{'positions'} } };
	if (%pos) {
		Kephra::Document::Change::to_number( $pos{'document'} )
			if $pos{'document'} != &Kephra::Document::_get_current_nr;
		$ep->SetCurrentPos( $pos{'pos'} );
		$ep->GotoLine( $pos{'line'} ) if $ep->GetCurrentLine != $pos{'line'};
		if ( $ep->GetColumn( $ep->GetCurrentPos ) == $pos{'col'} ) {
			$ep->SetSelection( $pos{'sel_begin'}, $pos{'sel_end'} );
		} else {
			my $npos = $ep->PositionFromLine( $pos{'line'} ) + $pos{'col'};
			my $max = $ep->GetLineEndPosition( $pos{'line'} );
			$npos = $max if $npos > $max;
			$ep->SetCurrentPos($npos);
			$ep->SetSelection( $npos, $npos );
		}
	}
	&_let_caret_visible;
}

sub _select_all_if_none {
	my $ep = Kephra::App::EditPanel::_get();
	my ($start, $end) = $ep->GetSelection;
	if ( $start == $end ) {
		$ep->SelectAll;
		$start = $ep->GetSelectionStart;
		$end   = $ep->GetSelectionEnd;
	}
	return $ep->GetTextRange( $start, $end );
}

sub can_paste { Kephra::App::EditPanel::_get()->CanPaste }
sub can_copy  { $Kephra::temp{'current_doc'}{'text_selected'} }

# simple textedit
sub cut       { Kephra::App::EditPanel::_get()->Cut }
sub copy      { Kephra::App::EditPanel::_get()->Copy }
sub paste     { Kephra::App::EditPanel::_get()->Paste }

sub replace {
	my $ep = Kephra::App::EditPanel::_get();
	my $length = ( $ep->GetSelectionEnd - $ep->GetSelectionStart );
	$ep->BeginUndoAction;
	$ep->SetSelectionEnd( $ep->GetSelectionStart );
	$ep->Paste;
	$ep->SetSelectionEnd( $ep->GetSelectionStart + $length );
	$ep->Cut;
	$ep->EndUndoAction;
}

sub clear { Kephra::App::EditPanel::_get()->Clear; }

sub del_back_tab{
	my $ep = Kephra::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos();
	my $tab_size = $Kephra::document{'current'}{'tab_size'};
	my $deltaspace = $ep->GetColumn($pos--) % $tab_size;
	$deltaspace = $tab_size unless $deltaspace;
	do { $ep->CmdKeyExecute(wxSTC_CMD_DELETEBACK) }
	while $ep->GetCharAt(--$pos) == 32 and --$deltaspace;
}


# Edit Selection

sub selection_move {
	my ( $ep, $linedelta ) = @_;
	my $text = $ep->GetSelectedText();

	$ep->BeginUndoAction;
	$ep->ReplaceSelection("");
	my $targetline = $ep->GetCurrentLine + $linedelta;
	my $lastline   = $ep->LineFromPosition(
		$ep->PositionFromLine( $ep->GetLineCount ) );
	$targetline = 0         if ( $targetline < 0 );
	$targetline = $lastline if ( $targetline > $lastline );
	my ( $oldpos, $oldline ) = ( $ep->GetCurrentPos, $ep->GetCurrentLine );
	my ( $posinline, $newpos)= ( $oldpos - $ep->PositionFromLine($oldline), 0 );

	if ($ep->GetLineEndPosition($targetline) - $ep->PositionFromLine($targetline)
		  < $posinline ) {
		$newpos = $ep->GetLineEndPosition($targetline);
	} else { $newpos = $ep->PositionFromLine($targetline) + $posinline }

	$ep->SetCurrentPos($newpos);
	$ep->InsertText( $newpos, $text );
	$ep->SetSelection( $newpos, $newpos + length($text) );
	$ep->EndUndoAction;
	&_let_caret_visible;
}

sub selection_move_left {
	my $ep = Kephra::App::EditPanel::_get();
	if ( $ep->GetSelectionStart > 0 ) {
		my $text = $ep->GetSelectedText();
		my $eoll = $Kephra::temp{'current_doc'}{'EOL_length'};
		$ep->BeginUndoAction;
		$ep->ReplaceSelection("");
		my $pos = $ep->GetCurrentPos;
		if ( $ep->GetColumn($pos) ) { $pos -= 1 }
		else                        { $pos -= $eoll }
		$ep->SetCurrentPos($pos);
		$ep->InsertText( $pos, $text );
		$ep->SetSelection( $pos, $pos + length($text) );
		$ep->EndUndoAction;
	}
}

sub selection_move_right {
	my $ep = Kephra::App::EditPanel::_get();
	if ( $ep->GetSelectionEnd < $ep->GetTextLength ) {
		my $text = $ep->GetSelectedText;
		my $eoll = $Kephra::temp{'current_doc'}{'EOL_length'};
		$ep->BeginUndoAction;
		$ep->ReplaceSelection("");
		my $pos  = $ep->GetCurrentPos;
		if ( $ep->GetColumn( $pos + $eoll ) ) { $pos += 1 }
		else                                  { $pos += $eoll }
		$ep->SetCurrentPos( $pos);
		$ep->InsertText( $pos, $text);
		$ep->SetSelection( $pos, $pos + length($text) );
		$ep->EndUndoAction;
	}
}

sub selection_move_up {
	my $ep = Kephra::App::EditPanel::_get();
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			$ep->CmdKeyExecute( wxSTC_CMD_LINETRANSPOSE );
			$ep->GotoLine( $ep->GetCurrentLine - 1 );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -1 );
		}
	}
}

sub selection_move_down {
	my $ep = Kephra::App::EditPanel::_get();
	if ($ep->LineFromPosition( $ep->GetSelectionEnd ) < $ep->GetLineCount - 1) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			$ep->GotoLine( $ep->GetCurrentLine + 1 );
			$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, 1 );
		}
	}
}

sub selection_move_page_up {
	my $ep  = Kephra::App::EditPanel::_get();
	my $linedelta = $ep->LinesOnScreen;
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			my $targetline = $ep->GetCurrentLine - $linedelta;
			$targetline = 0 if $targetline < 0;
			for my $i (reverse $targetline + 1 .. $ep->GetCurrentLine ) {
				$ep->GotoLine($i);
				$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->GotoLine( $ep->GetCurrentLine - 1 );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -$linedelta );
		}
	}
}

sub selection_move_page_down {
	my $ep  = Kephra::App::EditPanel::_get();
	my $linedelta = $ep->LinesOnScreen;
	if ($ep->LineFromPosition( $ep->GetSelectionEnd ) < $ep->GetLineCount - 1) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			my $targetline = $ep->GetCurrentLine + $linedelta;
			my $lastline   = $ep->LineFromPosition(
				$ep->PositionFromLine( $ep->GetLineCount ) );
			$targetline = $lastline if ( $targetline > $lastline );
			for my $i ($ep->GetCurrentLine + 1 .. $targetline) {
				$ep->GotoLine($i);
				$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, $linedelta );
		}
	}
}

# Edit Line
sub cut_current_line { Kephra::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_LINECUT) }
sub copy_current_line{ Kephra::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_LINECOPY)}
sub double_current_line {
	my $ep = Kephra::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos;
	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(wxSTC_CMD_LINECUT);
	$ep->CmdKeyExecute(wxSTC_CMD_PASTE);
	$ep->CmdKeyExecute(wxSTC_CMD_PASTE);
	$ep->GotoPos($pos);
	$ep->EndUndoAction;
}

sub replace_current_line {
	my $ep   = Kephra::App::EditPanel::_get();
	my $line = $ep->GetCurrentLine;
	$ep->BeginUndoAction;
	$ep->GotoLine($line);
	$ep->Paste;
	$ep->SetSelection( $ep->GetSelectionEnd,
		$ep->GetLineEndPosition( $ep->GetCurrentLine ) );
	$ep->Cut;
	$ep->GotoLine($line);
	$ep->EndUndoAction;
}

sub del_current_line{Kephra::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_LINEDELETE)}
sub del_line_left {Kephra::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_DELLINELEFT) }
sub del_line_right{Kephra::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_DELLINERIGHT)}

#
sub eval_newline_sub{
}

sub autoindent {
	my $ep  = Kephra::App::EditPanel::_get();
	my $line = $ep->GetCurrentLine;

	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
	my $indent = $ep->GetLineIndentation( $line );
	$ep->SetLineIndentation( $line + 1, $indent);
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );
	$ep->EndUndoAction;
}

sub blockindent_open {
	my $ep     = Kephra::App::EditPanel::_get();
	my $tabsize        = $Kephra::document{'current'}{'tab_size'};
	my $line           = $ep->GetCurrentLine;
	my $first_cpos     = $ep->PositionFromLine($line)
		+ $ep->GetLineIndentation($line); # position of first char in line
	my $matchfirst     = $ep->BraceMatch($first_cpos);

	$ep->BeginUndoAction;

	# dedent a "} else {" correct
	if ($ep->GetCharAt($first_cpos) == 125 and $matchfirst > -1) {
		$ep->SetLineIndentation( $line, $ep->GetLineIndentation(
				$ep->LineFromPosition($matchfirst) ) );
	}
	# grabbing
	my $bracepos   = $ep->GetCurrentPos - 1;
	my $leadindent = $ep->GetLineIndentation($line);
	my $matchbrace = $ep->BraceMatch( $bracepos );
	my $matchindent= $ep->GetLineIndentation($ep->LineFromPosition($matchbrace));

	# make newl line
	$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);

	# make new brace if there is missing one
	if ($Kephra::config{'editpanel'}{'auto'}{'brace'}{'make'} and
		($matchbrace == -1 or $ep->GetLineIndentation($line) != $matchindent )){
		$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
		$ep->AddText('}');
		$ep->SetLineIndentation( $line + 2, $leadindent );
	}
	$ep->SetLineIndentation( $line + 1, $leadindent + $tabsize );
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );

	$ep->EndUndoAction;
}

sub blockindent_close {
	my $ep = Kephra::App::EditPanel::_get();
	my $bracepos = shift;
	unless ($bracepos) {
		$bracepos = $ep->GetCurrentPos - 1;
		$bracepos-- while $ep->GetCharAt($bracepos) == 32;
	}

	$ep->BeginUndoAction;

	# 1 wenn text dahinter geh in neue zeile
	my $match = $ep->BraceMatch($bracepos);
	my $line  = $ep->GetCurrentLine;
	unless ($ep->GetLineIndentPosition($line)+1 == $ep->GetLineEndPosition($line)
		or  $ep->LineFromPosition($match) == $line ) {
		$ep->GotoPos($bracepos);
		$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
		$ep->GotoPos( $ep->GetCurrentPos + 1 );
		$line++;
	}

	# 2 wenn match dann korrigiere einrückung ansonst letzte - tabsize
	if ( $match > -1 ) {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $ep->LineFromPosition($match) ) );
	} else {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $line - 1 )
				- $Kephra::document{'current'}{'tab_size'} );
	}

	# make new line
	$Kephra::config{'editpanel'}{'auto'}{'indent'}
		? autoindent()
		: $ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);

	# 3 lösche dubs wenn in nächster zeile nur spaces bis dup
	if ( $Kephra::config{'editpanel'}{'auto'}{'brace'}{'join'} ) {
		my $delbrace = $ep->PositionFromLine( $line + 2 )
			+ $ep->GetLineIndentation( $line + 1 );
		if ( $ep->GetCharAt($delbrace) == 125 ) {
			$ep->SetTargetStart( $ep->GetCurrentPos );
			$ep->SetTargetEnd( $delbrace + 1 );
			$ep->ReplaceTarget('');
		}
	}

	$ep->EndUndoAction;
}

##########################

1;
