package Kepher::Edit::Goto;
$VERSION = '0.04';

# editpanel navigation

use strict;
use Wx qw( wxCANCEL wxSTC_CMD_PARAUP wxSTC_CMD_PARADOWN wxSTC_FIND_REGEXP);

sub line_nr {
	my $line = Kepher::Dialog::get_number( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'edit'}{'goto_line_input'},
		$Kepher::localisation{'dialog'}{'edit'}{'goto_line_headline'},
		Kepher::App::EditPanel::_get()->GetCurrentLine
	);
	Kepher::Edit::_goto_pos( Kepher::App::EditPanel::_get->PositionFromLine($line - 1) )
		unless $line == wxCANCEL;
}

sub last_edit {
	Kepher::Edit::_goto_pos($Kepher::document{'current'}{'edit_pos'})
		if defined $Kepher::document{'current'}{'edit_pos'};
}


# block navigation
sub prev_block{ Kepher::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_PARAUP) }
sub next_block{ Kepher::App::EditPanel::_get()->CmdKeyExecute(wxSTC_CMD_PARADOWN) }


# brace navigation
sub prev_brace{
	my $ep  = Kepher::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos - 1) if $ep->BraceMatch($pos) > -1;
	$ep->GotoPos($pos - 2) if $ep->BraceMatch($pos - 1) > -1;
	$ep->SearchAnchor();
	my $newpos = $ep->SearchPrev(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub next_brace{
	my $ep  = Kepher::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos + 1);
	$ep->SearchAnchor();
	my $newpos = $ep->SearchNext(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub prev_related_brace{
	my $ep  = Kepher::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch(--$pos);
	$matchpos = $ep->BraceMatch(++$pos) if $matchpos == -1;
	if ($matchpos == -1) { prev_brace() }
	else {
		if ($matchpos < $pos) { $ep->GotoPos($matchpos+1) }
		else{
			my $open_char = chr $ep->GetCharAt($pos);
			my $close_char = chr $ep->GetCharAt($matchpos);
			$ep->GotoPos($pos);
			$ep->SearchAnchor();
			my $next_open = $ep->SearchPrev(0, $open_char);
			$ep->GotoPos($pos);
			$ep->SearchAnchor();
			my $next_close = $ep->SearchPrev(0, $close_char);
			if ($next_open < $next_close) { $ep->GotoPos( $next_open + 1 ) }
			else                          { $ep->GotoPos( $next_close    ) }
		}
	}
}

sub next_related_brace{
	my $ep  = Kepher::App::EditPanel::_get();
	my $pos = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch($pos);
	$matchpos = $ep->BraceMatch(--$pos) if $matchpos == -1;
	if ($matchpos == -1) { next_brace() }
	else {
		if ($matchpos > $pos) { $ep->GotoPos($matchpos) }
		else{
			my $open_char = chr $ep->GetCharAt($matchpos);
			my $close_char = chr $ep->GetCharAt($pos);
			$ep->GotoPos($pos + 1);
			$ep->SearchAnchor();
			my $next_open = $ep->SearchNext(0, $open_char);
			$ep->GotoPos($pos + 1);
			$ep->SearchAnchor();
			my $next_close = $ep->SearchNext(0, $close_char);
			if ($next_open < $next_close) { $ep->GotoPos( $next_open + 1 ) }
			else                          { $ep->GotoPos( $next_close    ) }
		}
	}
}

1;