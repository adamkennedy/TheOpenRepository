package Kephra::Edit::Search;
$VERSION = '0.26';

# internal and menu functions about find and replace text
# drag n drop target class

use strict;
use Wx qw(
	wxSTC_FIND_WHOLEWORD wxSTC_FIND_MATCHCASE wxSTC_FIND_WORDSTART
	wxSTC_INDIC_STRIKE wxSTC_INDIC_DIAGONAL wxSTC_INDIC_TT wxSTC_INDIC_PLAIN
	wxSTC_FIND_REGEXP wxYES wxCANCEL
);

# Kephra::Dialog::msg_box(undef, "", " ");
#my $t0 = new Benchmark;print "find dups:",Benchmark::timestr(Benchmark::timediff(new Benchmark, $t0)),"\n";

# internal functions
sub _get_attributes{ $Kephra::config{'search'}{'attribute'} }
sub _get_history   { $Kephra::config{'search'}{'history'} }

sub _refresh_search_flags {
	my $attr = _get_attributes();
	my $flags = 0;

	$flags |= wxSTC_FIND_MATCHCASE
		if defined $attr->{'match_case'} and $attr->{'match_case'} eq 1;
	if (defined $attr->{'match_whole_word'} and $attr->{'match_whole_word'} eq 1 ) {
		$flags |= wxSTC_FIND_WHOLEWORD
	} else {
		$flags |= wxSTC_FIND_WORDSTART
			if $attr->{'match_word_begin'} and $attr->{'match_word_begin'} eq 1;
	}
	$flags |= wxSTC_FIND_REGEXP
		if defined $attr->{'match_regex'} and $attr->{'match_regex'} == 1;
	$Kephra::temp{'search'}{'flags'} = $flags;
}

sub _init_history {
	my $history = _get_history();

	# remove dups and cut to the configured length
	if ( $history->{'use'} ) {
		my ( %seen1, %seen2 );
		my @items = @{ Kephra::Config::_convert_node_2_AoS( \$history->{'find_item'} ) };
		my @uniq = grep { !$seen1{$_}++ } @items;
		@{ $history->{'find_item'} } = splice @uniq, 0, $history->{'length'};
		@items = @{ Kephra::Config::_convert_node_2_AoS( \$history->{'replace_item'} ) };
		@uniq = grep { !$seen2{$_}++ } @items;
		@{ $history->{'replace_item'} } = splice @uniq, 0, $history->{'length'};
	} else {
		@{ $history->{'find_item'} }    = ();
		@{ $history->{'replace_item'} } = ();
	}
}

sub refresh_find_history {
	my $found_match       = shift;
	my $current_find_item = get_find_item();
	my $history           = _get_history();
	my $refresh_needed;

	# check if refresh needed
	if ( $history->{'remember_only_matched'} ) {
		$refresh_needed = 1 if defined $found_match and $found_match > 0;
	} else { $refresh_needed = 1 }

	# delete dups
	if ($refresh_needed and _exist_find_item() 
		and ($history->{'find_item'})[0] ne $current_find_item) {
		my $item   = $history->{'find_item'};
		my $length = $history->{'length'} - 1;
		for ( 0 .. $#{$item} ) {
			if ( $$item[$_] eq $current_find_item ) {
				@{$item} = @{$item}[ 0 .. $_ - 1, $_ + 1 .. $#{$item} ];
				last;
			}
			pop @{$item} if ( $_ == $length );
		}

		# new history item
		unshift @{$item}, $current_find_item;
		$Kephra::temp{'search'}{'history'}{'refresh'} = 1;
	}
	$Kephra::temp{'search'}{'history'}{'refresh'} = 0;
}

sub refresh_replace_history {
	my $current_item = get_replace_item();
	my $history      = _get_history();

	if ($current_item) {
		my $item   = \@{ $history->{'replace_item'} };
		my $length = $history->{'length'} - 1;
		for ( 0 .. $#{$item} ) {
			if ( $$item[$_] eq $current_item ) {
				@{$item} = @{$item}[ 0 .. $_ - 1, $_ + 1 .. $#{$item} ];
				last;
			}
			pop @{$item} if ( $_ == $length );
		}
		unshift @{$item}, $current_item;
	}
}

sub _caret_2_sel_end {
	my $ep = Kephra::App::EditPanel::_get();
	my $pos       = $ep->GetCurrentPos;
	my $sel_start = $ep->GetSelectionStart;
	my $sel_end   = $ep->GetSelectionEnd;
	if ( $pos != $sel_end ) {
		$ep->SetCurrentPos($sel_end);
		$ep->SetSelectionStart($sel_start);
	}
}

sub _exist_find_item    { length( get_find_item() ) }
sub _exist_replace_item { length( get_replace_item() ) }
#
#
#
sub set_range{ _get_attributes()->{'in'} = shift}
sub get_range{ _get_attributes()->{'in'} }

sub get_attribute{
	my $attr = shift;
	if ($attr eq 'match_case'      or 
		$attr eq 'match_word_begin'or
		$attr eq 'match_whole_word'or
		$attr eq 'match_regex'     or
		$attr eq 'auto_wrap'       or
		$attr eq 'incremental'       ) {
		$Kephra::config{'search'}{'attribute'}{$attr}
	}
}

sub switch_attribute{
	my $attr = shift;
	if ($attr eq 'match_case'      or 
		$attr eq 'match_word_begin'or
		$attr eq 'match_whole_word'or
		$attr eq 'match_regex'     or
		$attr eq 'auto_wrap'       or
		$attr eq 'incremental'       ) {
		$Kephra::config{'search'}{'attribute'}{$attr} ^= 1;
		_refresh_search_flags() if substr($attr, 0, 1) eq 'm';
	}
}

# find helper function
sub get_find_item {
	my $h = _get_history();
	$h->{'current_find_item'} if defined $h->{'current_find_item'};
}

sub set_find_item {
	my $old = get_find_item();
	my $new = shift;
#print "set_find_item\n";
	if (defined $new and $new ne $old){
#print "find item changed $new ne $old \n";
		$Kephra::config{'search'}{'history'}{'current_find_item'} = $new;
		Kephra::App::EventList::trigger('find.item.changed');
	}
}

sub set_selection_as_find_item {
	set_find_item( Kephra::App::EditPanel::_get()->GetSelectedText )
}

sub get_replace_item {
	$Kephra::config{'search'}{'history'}{'current_replace_item'}
		if defined $Kephra::config{'search'}{'history'}{'current_replace_item'}
}

sub set_replace_item {
	my $old = $Kephra::config{'search'}{'history'}{'current_replace_item'};
	my $new = shift;
	if (defined $new and $new ne $old){
		$Kephra::config{'search'}{'history'}{'current_replace_item'} = $new;
		Kephra::App::EventList::trigger('replace.item.changed');
	}
}

sub set_selection_as_replace_item{
	set_replace_item( Kephra::App::EditPanel::_get()->GetSelectedText )
}

sub replace_selection  {
	Kephra::App::EditPanel::_get()->ReplaceSelection( get_replace_item() )
}

sub _find_next  {
	my $ep = Kephra::App::EditPanel::_get();
	$ep->SearchAnchor;
	return $ep->SearchNext(
		$Kephra::temp{'search'}{'flags'},
		get_find_item()
	);
}

sub _find_prev  {
	my $ep = Kephra::App::EditPanel::_get();
	$ep->SearchAnchor;
	return $ep->SearchPrev(
		$Kephra::temp{'search'}{'flags'},
		get_find_item()
	);
}

sub _find_first {
	Kephra::Edit::_goto_pos(0);
	return &_find_next;
}

sub _find_last  {
	Kephra::Edit::_goto_pos(-1);
	&_find_prev;
}

# find related menu calls
sub first_increment {
	my $ep = Kephra::App::EditPanel::_get();
	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions;
		if ( _find_first() > -1 ) {
			#_caret_2_sel_end();
			Kephra::Edit::_let_caret_visible;
			return 1;
		}
	}
	$ep->GotoPos( $Kephra::temp{'search'}{'old_pos'} )
		if defined $Kephra::temp{'search'}{'old_pos'};
	return 0;
}

sub next_increment {
}

sub find_all{
#Kephra::Dialog::msg_box(undef, Wx::wxUNICODE(), '');
	my $ep = Kephra::App::EditPanel::_get();
	if ( _exist_find_item() ) {
		my $search_result = _find_first();
		my ($sel_start, $sel_end);
		#Kephra::Dialog::msg_box(undef, , '');
		#$ep->IndicatorSetStyle(0, wxSTC_INDIC_TT );
		#$ep->IndicatorSetForeground(0, Wx::Colour->new(0xff, 0x00, 0x00));
		#$ep->IndicatorSetStyle(1, wxSTC_INDIC_TT );
		#$ep->IndicatorSetForeground(1, Wx::Colour->new(0xff, 0x00, 0x00));
		$ep->IndicatorSetStyle(1, wxSTC_INDIC_TT );
		$ep->IndicatorSetForeground(1, Wx::Colour->new(0xff, 0x00, 0x00));
		# ^= wxSTC_INDIC_STRIKE;
		$ep->SetSelection(0,0);
		return 0 if $search_result == -1;
		while ($search_result > -1){
			($sel_start, $sel_end) = $ep->GetSelection;
			Kephra::Edit::_goto_pos( $sel_end );
			$ep->StartStyling($sel_start, 224);#224
			$ep->SetStyleBytes($sel_end - $sel_start, 128);
			$search_result = _find_next();
		}
		Kephra::Edit::_goto_pos( $sel_end );
		$ep->Colourise( 0, $sel_end);
		return 1;
	} else {
		$ep->GotoPos( $Kephra::temp{'search'}{'old_pos'} )
			if defined $Kephra::temp{'search'}{'old_pos'};
		return 1;
	}
}

sub find_prev {
	my $ep    = Kephra::App::EditPanel::_get();
	my $attr = \%{ $Kephra::config{'search'}{'attribute'} };
	my $return = -1;
	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions;
		Kephra::Edit::_goto_pos( $ep->GetSelectionStart - 1 );
		$return = _find_prev();
		if ( $return == -1 ) {
			if ( get_range() eq 'document' ) {
				$return = _find_last() if $attr->{'auto_wrap'};
			} elsif ( get_range() eq 'open_docs' ) {
				$Kephra::temp{'dialog'}{'control'} = 1;
				my $begin_doc = Kephra::Document::_get_current_nr();
				while ( $return == -1 ) {
					Kephra::Edit::_restore_positions;
					last
						if ( ( &Kephra::Document::_get_current_nr == 0 )
						and !$attr->{'auto_wrap'} );
					Kephra::Document::Change::tab_left();
					Kephra::Edit::_save_positions();
					$return = _find_last();
					last
						if ( Kephra::Document::_get_current_nr() == $begin_doc );
				}
				$Kephra::temp{'dialog'}{'control'} = 0;
				Kephra::Dialog::Search::_get()->Raise
					if $Kephra::temp{'dialog'}{'search'}{'active'};
			}
		}
		if ( $return == -1 ) { &Kephra::Edit::_restore_positions; }
		else { _caret_2_sel_end(); &Kephra::Edit::_let_caret_visible; }
		refresh_find_history($return);
	}
	$return;
}

sub find_next {
	my $ep    = Kephra::App::EditPanel::_get();
	my $attr = \%{ $Kephra::config{'search'}{'attribute'} };
	my $return = -1;

	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions();
		Kephra::Edit::_goto_pos( $ep->GetSelectionEnd );
		$return = _find_next();
		if ( $return == -1 ) {
			if ( get_range() eq 'document' ) {
				$return = &_find_first if $attr->{'auto_wrap'};
			} elsif ( get_range() eq 'open_docs' ) {
				$Kephra::temp{'dialog'}{'control'} = 1;
				my $begin_doc = &Kephra::Document::_get_current_nr;
				while ( $return == -1 ) {
					&Kephra::Edit::_restore_positions;
					last if &Kephra::Document::_get_current_nr
							== Kephra::Document::_get_last_nr()
						 and not $attr->{'auto_wrap'};
					Kephra::Document::Change::tab_right();
					Kephra::Edit::_save_positions();
					$return = &_find_first;
					last if ( &Kephra::Document::_get_current_nr == $begin_doc );
				}
				$Kephra::temp{'dialog'}{'control'} = 0;
				Kephra::Dialog::Search::_get()->Raise
					if $Kephra::temp{'dialog'}{'search'}{'active'};
			}
		}
		if ( $return == -1 ) { &Kephra::Edit::_restore_positions; }
		else { _caret_2_sel_end(); &Kephra::Edit::_let_caret_visible; }
		refresh_find_history($return);
	}
	$return;
}

sub fast_back {
	my $ep = &Kephra::App::EditPanel::_get;
	my $attr = \%{ $Kephra::config{'search'}{'attribute'} };
	my $return    = -1;
	if (&_exist_find_item) {
		for ( 1 .. $attr->{'fast_steps'} ) {
			&Kephra::Edit::_save_positions;
			Kephra::Edit::_goto_pos( $ep->GetSelectionStart - 1 );
			$return = &_find_prev;
			if ( $return == -1 ) {
				if ( get_range() eq 'document' ) {
					$return = &_find_last if $attr->{'auto_wrap'};
				} elsif ( get_range() eq 'open_docs' ) {
					$Kephra::temp{'dialog'}{'control'} = 1;
					my $begin_doc = &Kephra::Document::_get_current_nr;
					while ( $return == -1 ) {
						&Kephra::Edit::_restore_positions;
						last if &Kephra::Document::_get_current_nr == 0
							and not $attr->{'auto_wrap'};
						&Kephra::Document::Change::tab_left;
						&Kephra::Edit::_save_positions;
						$return = &_find_last;
						last if &Kephra::Document::_get_current_nr == $begin_doc;
					}
					$Kephra::temp{'dialog'}{'control'} = 0;
					Kephra::Dialog::Search::_get()->Raise
						if $Kephra::temp{'dialog'}{'search'}{'active'};
				}
			}
			refresh_find_history($return) if ( $_ == 1 );
			if ( $return == -1 ) { &Kephra::Edit::_restore_positions; last; }
			else { _caret_2_sel_end(); &Kephra::Edit::_let_caret_visible; }
		}
	}
}

sub fast_fore {
	my $ep = &Kephra::App::EditPanel::_get;
	my $attr = $Kephra::config{'search'}{'attribute'};
	my $return    = -1;
	if (&_exist_find_item) {
		for ( 1 .. $attr->{'fast_steps'} ) {
			&Kephra::Edit::_save_positions;
			Kephra::Edit::_goto_pos( $ep->GetSelectionEnd );
			$return = &_find_next;
			if ( $return == -1 ) {
				if ( get_range() eq 'document' ) {
					$return = &_find_first if $attr->{'auto_wrap'};
				} elsif ( get_range() eq 'open_docs' ) {
					$Kephra::temp{'dialog'}{'control'} = 1;
					my $begin_doc = &Kephra::Document::_get_current_nr;
					while ( $return == -1 ) {
						&Kephra::Edit::_restore_positions;
						last if Kephra::Document::_get_current_nr()
								== Kephra::Document::_get_last_nr()
							and not $attr->{'auto_wrap'};
						&Kephra::Document::Change::tab_right;
						&Kephra::Edit::_save_positions;
						$return = &_find_first;
						last if &Kephra::Document::_get_current_nr == $begin_doc;
					}
					$Kephra::temp{'dialog'}{'control'} = 0;
					Kephra::Dialog::Search::_get()->Raise
						if $Kephra::temp{'dialog'}{'search'}{'active'};
				}
			}
			refresh_find_history($return) if $_ == 1;
			if ( $return == -1 ) { &Kephra::Edit::_restore_positions; last; }
			else { _caret_2_sel_end(); &Kephra::Edit::_let_caret_visible; }
		}
	}
}

sub find_first {
	my $menu_call = shift;
	my $ep = &Kephra::App::EditPanel::_get;
	my $attr = $Kephra::config{'search'}{'attribute'};
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if ( _exist_find_item() ) {
		&Kephra::Edit::_save_positions;
		if ($menu_call
		and $sel_begin != $sel_end
		and $sel_end - $sel_begin > $len ) {
			set_range('selection') 
		}
		if ( get_range() eq 'selection' ) {
			Kephra::Edit::_goto_pos($sel_begin);
			$return = &_find_next;
			if ($return > -1 and $ep->GetCurrentPos + $len <= $sel_end) {
				&Kephra::Edit::_let_caret_visible;
			} else {
				&Kephra::Edit::_restore_positions;
				$return = -1;
			}
		} else {
			$return = &_find_first;
			if ( get_range() eq 'open_docs'
			and ($sel_begin == $ep->GetSelectionStart or $return == -1 ) ){
				$Kephra::temp{'dialog'}{'control'} = 1;
				$return = -1;
				my $begin_doc = &Kephra::Document::_get_current_nr;
				while ( $return == -1 ) {
					&Kephra::Edit::_restore_positions;
					last if &Kephra::Document::_get_current_nr == 0
						and not $attr->{'auto_wrap'};
					Kephra::Document::Change::tab_left();
					&Kephra::Edit::_save_positions;
					$return = &_find_first;
					last if ( &Kephra::Document::_get_current_nr == $begin_doc );
				}
				$Kephra::temp{'dialog'}{'control'} = 0;
				Kephra::Dialog::Search::_get()->Raise
					if $Kephra::temp{'dialog'}{'search'}{'active'};
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				&Kephra::Edit::_let_caret_visible;
			} else {
				&Kephra::Edit::_restore_positions;
			}
		}
		refresh_find_history($return);
	}
	$return;
}

sub find_last {
	my $menu_call = shift;
	my $ep = &Kephra::App::EditPanel::_get;
	my $attr = $Kephra::config{'search'}{'attribute'};
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if (&_exist_find_item) {
		&Kephra::Edit::_save_positions;
		if ($menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len) {
			set_range('selection');
		}
		if ( get_range() eq 'selection' ) {
			Kephra::Edit::_goto_pos($sel_end);
			$return = &_find_prev;
			if ($return > -1 and $ep->GetCurrentPos >= $sel_begin) {
				&Kephra::Edit::_let_caret_visible;
			} else {
				&Kephra::Edit::_restore_positions;
				$return = -1;
			}
		} else {
			$return = &_find_last;
			if (get_range() eq 'open_docs'
				and ($sel_begin == $ep->GetSelectionStart or $return == -1) ){
				$Kephra::temp{'dialog'}{'control'} = 1;
				$return = -1;
				my $begin_doc = &Kephra::Document::_get_current_nr;
				while ( $return == -1 ) {
					&Kephra::Edit::_restore_positions;
					last if Kephra::Document::_get_current_nr()
							== Kephra::Document::_get_last_nr()
						and not $attr->{'auto_wrap'};
					Kephra::Document::Change::tab_right();
					&Kephra::Edit::_save_positions;
					$return = &_find_last;
					last if ( &Kephra::Document::_get_current_nr == $begin_doc );
				}
				$Kephra::temp{'dialog'}{'control'} = 0;
				Kephra::Dialog::Search::_get()->Raise
					if $Kephra::temp{'dialog'}{'search'}{'active'};
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				Kephra::Edit::_let_caret_visible();
			} else {
				Kephra::Edit::_restore_positions();
			}
		}
		refresh_find_history($return);
	}
	$return;
}

  # replace
sub replace_back {
	my $ep = Kephra::App::EditPanel::_get();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		replace_selection();
		refresh_replace_history();
		find_prev();
	}
}

sub replace_fore {
	my $ep = Kephra::App::EditPanel::_get();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		replace_selection();
		refresh_replace_history();
		find_next();
	}
}

sub replace_all {
	my $menu_call = shift;
	my $ep = &Kephra::App::EditPanel::_get;
	my ($sel_begin, $sel_end ) = $ep->GetSelection;
	my $line           = $ep->GetCurrentLine;
	my $len            = _exist_find_item();
	my $replace_string = get_replace_item();
	if ($len) {
		if (    $menu_call
		    and $sel_begin != $sel_end 
			and $sel_end - $sel_begin > $len ) {
			$Kephra::config{'search'}{'attribute'}{'in'} = 'selection';
		}
		if ( get_range() eq 'selection' ) {
			$ep->BeginUndoAction;
			$ep->GotoPos($sel_begin);
			while ( &_find_next > -1 ) {
				last if ( $ep->GetCurrentPos + $len >= $sel_end );
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( get_range() eq 'document' ) {
			$ep->BeginUndoAction;
			$ep->GotoPos(0);
			while ( &_find_next > -1 ) {
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( get_range() eq 'open_docs' ) {
			my $begin_doc = &Kephra::Document::_get_current_nr;
			do {
				{
					&Kephra::Edit::_save_positions;
					$ep->BeginUndoAction;
					$ep->GotoPos(0);
					while ( &_find_next > -1 ) {
						$ep->ReplaceSelection($replace_string);
					}
					$ep->EndUndoAction;
					&Kephra::Edit::_restore_positions;
				}
			} until ( Kephra::Document::Change::tab_right() == $begin_doc );
		}
		$ep->GotoLine($line);
		refresh_replace_history;
		Kephra::Edit::_keep_focus();
	}
}

sub replace_confirm {
	if (&_exist_find_item) {
		my $ep = Kephra::App::EditPanel::_get();
		my $attr = $Kephra::config{'search'}{'attribute'};
		my $line = $ep->LineFromPosition( $ep->GetCurrentPos );
		my $len  = _exist_find_item();
		my $sel_begin = $ep->GetSelectionStart;
		my $sel_end   = $ep->GetSelectionEnd;
		my $answer    = wxYES;
		my $menu_call = shift;

		set_range('selection')
			if $menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len;

		if (get_range() eq 'selection') {
			sniff_selection( $ep, $sel_begin, $sel_end, $len, $line );
		} elsif (get_range() eq 'document') {
			sniff_selection( $ep, 0, $ep->GetTextLength, $len, $line );
		} elsif (get_range() eq 'open_docs') {
			my $begin_doc = &Kephra::Document::_get_current_nr;
			do {
				{
					next if $answer == wxCANCEL;
					&Kephra::Edit::_save_positions;
					$answer = &sniff_selection( $ep, 0,
						$ep->GetTextLength, $len, $line );
					&Kephra::Edit::_restore_positions;
				}
			} until ( Kephra::Document::Change::tab_right() == $begin_doc );
		}
	}

	sub sniff_selection {
		my ( $ep, $sel_begin, $sel_end, $len, $line ) = @_;
		my $l10n = $Kephra::localisation{'dialog'}{'search'}{'confirm'};
		my $answer;
		&Kephra::Edit::_goto_pos($sel_begin);
		$ep->BeginUndoAction();
		while ( &_find_next > -1 ) {
			last if $ep->GetCurrentPos + $len >= $sel_end;
			&Kephra::Edit::_let_caret_visible;
			$answer = Kephra::Dialog::get_confirm_3
				(undef, $l10n->{'text'}, $l10n->{'title'}, 100, 100);
			last if $answer == wxCANCEL;
			if ($answer == wxYES) {&replace_selection}
			else                  {$ep->SetCurrentPos( $ep->GetCurrentPos + 1 )}
		}
		$ep->EndUndoAction;
		&Kephra::Edit::_goto_pos( $ep->PositionFromLine($line) );
		&Kephra::Edit::_let_caret_visible;
		$answer;
	}
	refresh_replace_history();
	Kephra::Edit::_keep_focus();
}


#
package SearchInputTarget;
our $VERSION = '0.04';

use strict;
use base qw(Wx::TextDropTarget);

sub new {
	my $class  = shift;
	my $target  = shift;
	my $kind  = shift;
	my $self = $class->SUPER::new(@_);
	$self->{target} = $target if substr(ref $target, 0, 12) eq 'Wx::ComboBox';
	$self->{kind} = $kind;
	return $self;
}

sub OnDropText {
	my ( $self, $x, $y, $text ) = @_;
	$self->{target}->SetValue( $text ) if $self->{target};
	$self->{kind} eq 'replace'
		? Kephra::Edit::Search::set_replace_item($text)
		: Kephra::Edit::Search::set_find_item($text);
	0; #dont skip event
}

1;