package KEPHER::Edit::Format;
$VERSION = '0.22';

use strict;
use Wx qw(
	wxSTC_CMD_NEWLINE wxSTC_CMD_DELETEBACK wxSTC_CMD_LINEEND
	wxSTC_CMD_WORDLEFT wxSTC_CMD_WORDRIGHT
);

# indention
sub _indent {
	my $width = shift;
	my $ep    = KEPHER::App::STC::_get();
	$width ||= 0;
	$ep->BeginUndoAction;
	$ep->SetLineIndentation( $_, $ep->GetLineIndentation($_) + $width ) 
		for $ep->LineFromPosition($ep->GetSelectionStart)
		 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction;
}

sub _dedent {
	my $width = shift;
	my $ep   = KEPHER::App::STC::_get();
	$ep->BeginUndoAction;
	$ep->SetLineIndentation( $_, $ep->GetLineIndentation($_) - $width )
		for $ep->LineFromPosition($ep->GetSelectionStart)
		 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction;
}

sub indent_space { _indent(1) }
sub dedent_space { _dedent(1) }
sub indent_tab   { _indent($KEPHER::document{'current'}{'tab_size'}) }
sub dedent_tab   { _dedent($KEPHER::document{'current'}{'tab_size'}) }

#
sub align_indent {
	my $ep = KEPHER::App::STC::_get();
	my $firstline = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $align = $ep->GetLineIndentation($firstline);
	$ep->BeginUndoAction();
	$ep->SetLineIndentation($_ ,$align)
		for $firstline + 1 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction();
}

# deleting trailing spaces on line ends
sub del_trailing_spaces {
	&KEPHER::Edit::_save_positions;
	my $ep = KEPHER::App::STC::_get();
	my $text = KEPHER::Edit::_select_all_if_non();
	$text =~ s/[ \t]+(\r|\n|\Z)/$1/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	KEPHER::Edit::_restore_positions();
}

#
sub join_lines {
 my $ep = KEPHER::App::STC::_get();
 my $text = $ep->GetSelectedText();
	$text =~ tr/\r\n//d; # delete end of line marker
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
}

sub blockformat{
}

sub blockformat_LLI{
	blockformat( $KEPHER::config{editpanel}{indicator}{right_margin}{position} );
}

sub blockformat_custom{
	my $width = KEPHER::Dialog::get_text( KEPHER::App::Window::_get(),
			$KEPHER::localisation{dialog}{edit}{wrap_width_input},
			$KEPHER::localisation{dialog}{edit}{wrap_custom_headline}
	);
	blockformat( $width ) if defined $width and $width;}


# breaking too long lines into smaller one
sub line_break {
	my $width = shift;
	my $ep    = &KEPHER::App::STC::_get;
	my $autoindent = $KEPHER::config{'editpanel'}{'auto'}{'indention'};
	my $eol_width  = $KEPHER::internal{'current_doc'}{'EOL_length'};
	my ($begin_pos, $end_pos) = ( $ep->GetSelectionStart, $ep->GetSelectionEnd );
	($begin_pos, $end_pos) = ($end_pos, $begin_pos) if $begin_pos > $end_pos;
	my $line = $ep->LineFromPosition( $begin_pos );
	my ($pos, $col, $indent, $line_end);

	$ep->BeginUndoAction();
	$ep->GotoPos($begin_pos);

	#while () {
		# position where this line will be broken
		$line_end = $ep->PositionFromLine($line) + $width;
#
		# last when end of selection is reached
		#last unless $pos < $end_pos;
#
		# skip and not brake short lines
		$ep->CmdKeyExecute(wxSTC_CMD_LINEEND);
		$col = $ep->GetColumn($ep->GetCurrentPos());
		if ($col > $line_end) {
			#$pos += $width - $col
			KEPHER::Dialog::msg_box( undef,);
		} else {
			$ep->GotoLine(++$line);
			#next; 
		}
#
		# brake always on and of the last word that fit into the line
		#if ( not ($pos == $ep->WordEndPosition($pos, 1)  )
		     #and ($pos == $ep->WordStartPosition($pos, 1))  ) {
			#$pos = $ep->WordStartPosition($pos, 1);
			#$pos = $ep->WordStartPosition($pos, 0);
		#}
#
		#$ep->GotoPos( $pos );
		#$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
		#$line++;
		#$indent = $ep->GetLineIndentation($line);
		#$end_pos += $eol_width - $indent;
		#if ($autoindent){
			#$indent = $ep->GetLineIndentation($line-1);
			#$ep->SetLineIndentation($line, $indent);
			#$end_pos += $indent;#length ($ep->GetTextRange());
		#} else { $ep->SetLineIndentation($line, 0) }
	#}

#$ep->WordStartPosition( $begin, 1 );
	$ep->GotoPos($end_pos);
	$ep->EndUndoAction();

	#KEPHER::Dialog::msg_box( undef, $ep->GetColumn($ep->GetCurrentPos()).$width,     '' );
	# GetLineEndPosition                                                  LineLength
	# $ep->CmdKeyExecute(wxSTC_CMD_WORDLEFT);#wxSTC_CMD_WORDRIGHT
	
#$ep->CmdKeyExecute(); #GetCharAt(position)   
#$KEPHER::internal{'edit'}{'wordchars'}WordEndPosition(pos, onlyWordCharacters) WordStartPosition(pos, onlyWordCharacters)
}

sub linebreak_custom {
	my $l10n = $KEPHER::localisation{dialog}{edit};
	my $width = KEPHER::Dialog::get_text( KEPHER::App::Window::_get(),
			$l10n->{wrap_width_input}, $l10n->{wrap_custom_headline} );
	line_break( $width ) if defined $width and $width;
}

sub linebreak_LLI {
	line_break( $KEPHER::config{editpanel}{indicator}{right_margin}{position} );
}

sub linebreak_window {
	my $app     = KEPHER::App::Window::_get();
	my $ep = KEPHER::App::STC::_get();
	my ($width) = $app->GetSizeWH();
	my $pos = $ep->GetColumn($ep->PositionFromPointClose(100, 67));
	KEPHER::Dialog::msg_box( $app, $pos, '' );
	#line_break($width);
}

1;
