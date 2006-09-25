package Kepher::App::EditPanel;
$VERSION = '0.02';

use strict;
use Wx qw();
#wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD

sub _get    { $Kepher::app{'editpanel'} }
sub _set    { $Kepher::app{'editpanel'} = shift }

sub _get_config { $Kepher::config{'editpanel'} }

sub create {
	my $ep = Wx::StyledTextCtrl->new
		(Kepher::App::Window::_get(), -1, [-1,-1], [-1,-1]);
	$ep->DragAcceptFiles(1);
	_set($ep);
	return $ep;
}

# bracelight
sub bracelight_visible{
	$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'}
}

sub apply_bracelight_settings{
	if (bracelight_visible()){
		Kepher::App::EventList::add_call
			('caret.move', 'bracelight', \&paint_bracelight);
		paint_bracelight();
	} else {
		Kepher::App::EventList::del_call('caret.move', 'bracelight');
		_get()->BraceHighlight( -1, -1 );
	}
}

sub paint_bracelight {
	my $ep       = _get();
	my $pos      = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch(--$pos);
	$matchpos = $ep->BraceMatch(++$pos) if $matchpos == -1;

	$ep->SetHighlightGuide(0);
	if ( $matchpos > -1 ) {
		# highlight braces
		$ep->BraceHighlight($matchpos, $pos);
		# asign pos to opening brace
		$pos = $matchpos if $matchpos < $pos;
		my $indent = $ep->GetLineIndentation( $ep->LineFromPosition($pos) );
		# highlighting indenting guide
		$ep->SetHighlightGuide($indent)
			if $indent % $Kepher::document{'current'}{'tab_size'} == 0;
	} else {
		# disbale all highlight
		$ep->BraceHighlight( -1, -1 );
		$ep->BraceBadLight($pos-1)
			if $ep->GetTextRange($pos-1,$pos) =~ /{|}|\(|\)|\[|\]/;
		$ep->BraceBadLight($pos)
			if $pos < $ep->GetTextLength
			and $ep->GetTextRange( $pos, $pos + 1 ) =~ tr/{}()\[\]//;
	}
}

sub get_view_EOL { $Kepher::config{editpanel}{indicator}{end_of_line_marker} }

1;