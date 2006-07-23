package PCE::Edit::Search;
$VERSION = '0.24';

# internal and menu functions about find and replace text
# drag n drop target class

use strict;
use Wx qw(
	wxSTC_FIND_WHOLEWORD wxSTC_FIND_MATCHCASE wxSTC_FIND_WORDSTART
	wxSTC_INDIC_STRIKE wxSTC_INDIC_DIAGONAL wxSTC_INDIC_TT wxSTC_INDIC_PLAIN
	wxSTC_FIND_REGEXP wxYES wxCANCEL
);

# PCE::Dialog::msg_box(undef, "", " ");
#my $t0 = new Benchmark;print "find dups:",Benchmark::timestr(Benchmark::timediff(new Benchmark, $t0)),"\n";

# internal functions
sub _init_history {
	my $history = $PCE::config{'search'}{'history'};

	# remove dups and cut to the configured length
	if ( $history->{'use'} ) {
		my ( %seen1, %seen2 );
		my @items = @{ PCE::Config::_convert_node_2_AoS( \$history->{'find_item'} ) };
		my @uniq = grep { !$seen1{$_}++ } @items;
		@{ $history->{'find_item'} } = splice @uniq, 0, $history->{'length'};
		@items = @{ PCE::Config::_convert_node_2_AoS( \$history->{'replace_item'} ) };
		@uniq = grep { !$seen2{$_}++ } @items;
		@{ $history->{'replace_item'} } = splice @uniq, 0, $history->{'length'};
	} else {
		@{ $history->{'find_item'} }    = ();
		@{ $history->{'replace_item'} } = ();
	}
}

sub get_attribute{
	my $attr = shift;
	if ($attr eq 'match_case'      or 
		$attr eq 'match_word_begin'or
		$attr eq 'match_whole_word'or
		$attr eq 'match_regex'     or
		$attr eq 'auto_wrap'       or
		$attr eq 'incremental'       ) {
		$PCE::config{'search'}{'attribute'}{$attr}
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
		$PCE::config{'search'}{'attribute'}{$attr} ^= 1;
		_refresh_search_flags() if substr($attr, 0, 1) eq 'm';
	}
}

sub _refresh_search_flags {
	my $attr = $PCE::config{'search'}{'attribute'};
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
	$PCE::internal{'search'}{'flags'} = $flags;
}

sub _refresh_find_history {
	my $found_match       = shift;
	my $current_find_item = get_find_item();
	my $history           = $PCE::config{'search'}{'history'};
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
		$PCE::internal{'search'}{'history'}{'refresh'} = 1;
	}
	$PCE::internal{'search'}{'history'}{'refresh'} = 0;
}

sub _refresh_replace_history {
	my $current_item = get_replace_item();
	my $history      = $PCE::config{'search'}{'history'};

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

sub _find_next  {
	my $ep = PCE::App::STC::_get();
	$ep->SearchAnchor;
	return $ep->SearchNext(
		$PCE::internal{'search'}{'flags'},
		get_find_item()
	);
}

sub _find_prev  {
	my $ep = PCE::App::STC::_get();
	$ep->SearchAnchor;
	return $ep->SearchPrev(
		$PCE::internal{'search'}{'flags'},
		get_find_item()
	);
}

sub _find_first {
	PCE::Edit::_goto_pos(0);
	return &_find_next;
}

sub _find_last  {
	PCE::Edit::_goto_pos(-1);
	&_find_prev;
}

sub _caret_2_sel_end    {
	my $ep = PCE::App::STC::_get();
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
sub _replace_selection  {
	PCE::App::STC::_get()->ReplaceSelection( get_replace_item() )
}
  # find helper function
sub get_find_item {
	$PCE::config{'search'}{'history'}{'current_find_item'}
		if defined $PCE::config{'search'}{'history'}{'current_find_item'}
}

sub set_find_item {
	$PCE::config{'search'}{'history'}{'current_find_item'} = shift
}

sub set_selection_as_find_item {
	set_find_item( PCE::App::STC::_get()->GetSelectedText )
}

sub get_replace_item {
	$PCE::config{'search'}{'history'}{'current_replace_item'}
		if defined $PCE::config{'search'}{'history'}{'current_replace_item'}
}

sub set_replace_item {
	$PCE::config{'search'}{'history'}{'current_replace_item'} = shift
}

sub set_selection_as_replace_item{
	set_replace_item( PCE::App::STC::_get()->GetSelectedText )
}
 # find related menu calls
sub first_increment {
	my $ep = PCE::App::STC::_get();
	if ( _exist_find_item() ) {
		PCE::Edit::_save_positions;
		if ( _find_first() > -1 ) {
			#_caret_2_sel_end();
			PCE::Edit::_let_caret_visible;
			return 1;
		}
	}
	$ep->GotoPos( $PCE::internal{'search'}{'old_pos'} )
		if defined $PCE::internal{'search'}{'old_pos'};
	return 0;
}

sub find_all{
#PCE::Dialog::msg_box(undef, Wx::wxUNICODE(), '');
	my $ep = PCE::App::STC::_get();
	if ( _exist_find_item() ) {
		my $search_result = _find_first();
		my ($sel_start, $sel_end);
		#PCE::Dialog::msg_box(undef, , '');
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
			PCE::Edit::_goto_pos( $sel_end );
			$ep->StartStyling($sel_start, 224);#224
			$ep->SetStyleBytes($sel_end - $sel_start, 128);
			$search_result = _find_next();
		}
		PCE::Edit::_goto_pos( $sel_end );
		$ep->Colourise( 0, $sel_end);
		return 1;
	} else {
		$ep->GotoPos( $PCE::internal{'search'}{'old_pos'} )
			if defined $PCE::internal{'search'}{'old_pos'};
		return 1;
	}
}

sub find_prev {
	my $ep    = PCE::App::STC::_get();
	my $attr = \%{ $PCE::config{'search'}{'attribute'} };
	my $return = -1;
	if ( _exist_find_item() ) {
		PCE::Edit::_save_positions;
		PCE::Edit::_goto_pos( $ep->GetSelectionStart - 1 );
		$return = _find_prev();
		if ( $return == -1 ) {
			if ( $attr->{'in'} eq 'document' ) {
				$return = _find_last() if $attr->{'auto_wrap'};
			} elsif ( $attr->{'in'} eq 'open_docs' ) {
				$PCE::internal{'dialog'}{'control'} = 1;
				my $begin_doc = PCE::Document::_get_current_nr();
				while ( $return == -1 ) {
					PCE::Edit::_restore_positions;
					last
						if ( ( &PCE::Document::_get_current_nr == 0 )
						and !$attr->{'auto_wrap'} );
					PCE::Document::Change::tab_left();
					PCE::Edit::_save_positions();
					$return = _find_last();
					last
						if ( PCE::Document::_get_current_nr() == $begin_doc );
				}
				$PCE::internal{'dialog'}{'control'} = 0;
				$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
					if $PCE::internal{'dialog'}{'search'}{'active'};
			}
		}
		if ( $return == -1 ) { &PCE::Edit::_restore_positions; }
		else { _caret_2_sel_end(); &PCE::Edit::_let_caret_visible; }
		_refresh_find_history($return);
	}
	$return;
}

sub find_next {
	my $ep    = PCE::App::STC::_get();
	my $attr = \%{ $PCE::config{'search'}{'attribute'} };
	my $return = -1;

	if ( _exist_find_item() ) {
		PCE::Edit::_save_positions();
		PCE::Edit::_goto_pos( $ep->GetSelectionEnd );
		$return = _find_next();
		if ( $return == -1 ) {
			if ( $attr->{'in'} eq 'document' ) {
				$return = &_find_first if $attr->{'auto_wrap'};
			} elsif ( $attr->{'in'} eq 'open_docs' ) {
				$PCE::internal{'dialog'}{'control'} = 1;
				my $begin_doc = &PCE::Document::_get_current_nr;
				while ( $return == -1 ) {
					&PCE::Edit::_restore_positions;
					last if &PCE::Document::_get_current_nr
							== PCE::Document::_get_last_nr()
						 and not $attr->{'auto_wrap'};
					PCE::Document::Change::tab_right();
					PCE::Edit::_save_positions();
					$return = &_find_first;
					last if ( &PCE::Document::_get_current_nr == $begin_doc );
				}
				$PCE::internal{'dialog'}{'control'} = 0;
				$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
					if $PCE::internal{'dialog'}{'search'}{'active'};
			}
		}
		if ( $return == -1 ) { &PCE::Edit::_restore_positions; }
		else { _caret_2_sel_end(); &PCE::Edit::_let_caret_visible; }
		_refresh_find_history($return);
	}
	$return;
}

sub fast_back {
	my $ep = &PCE::App::STC::_get;
	my $attr = \%{ $PCE::config{'search'}{'attribute'} };
	my $return    = -1;
	if (&_exist_find_item) {
		for ( 1 .. $attr->{'fast_steps'} ) {
			&PCE::Edit::_save_positions;
			PCE::Edit::_goto_pos( $ep->GetSelectionStart - 1 );
			$return = &_find_prev;
			if ( $return == -1 ) {
				if ( $attr->{'in'} eq 'document' ) {
					$return = &_find_last if $attr->{'auto_wrap'};
				} elsif ( $attr->{'in'} eq 'open_docs' ) {
					$PCE::internal{'dialog'}{'control'} = 1;
					my $begin_doc = &PCE::Document::_get_current_nr;
					while ( $return == -1 ) {
						&PCE::Edit::_restore_positions;
						last if &PCE::Document::_get_current_nr == 0
							and not $attr->{'auto_wrap'};
						&PCE::Document::Change::tab_left;
						&PCE::Edit::_save_positions;
						$return = &_find_last;
						last if &PCE::Document::_get_current_nr == $begin_doc;
					}
					$PCE::internal{'dialog'}{'control'} = 0;
					$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
						if $PCE::internal{'dialog'}{'search'}{'active'};
				}
			}
			_refresh_find_history($return) if ( $_ == 1 );
			if ( $return == -1 ) { &PCE::Edit::_restore_positions; last; }
			else { _caret_2_sel_end(); &PCE::Edit::_let_caret_visible; }
		}
	}
}

sub fast_fore {
	my $ep = &PCE::App::STC::_get;
	my $attr = $PCE::config{'search'}{'attribute'};
	my $return    = -1;
	if (&_exist_find_item) {
		for ( 1 .. $attr->{'fast_steps'} ) {
			&PCE::Edit::_save_positions;
			PCE::Edit::_goto_pos( $ep->GetSelectionEnd );
			$return = &_find_next;
			if ( $return == -1 ) {
				if ( $attr->{'in'} eq 'document' ) {
					$return = &_find_first if $attr->{'auto_wrap'};
				} elsif ( $attr->{'in'} eq 'open_docs' ) {
					$PCE::internal{'dialog'}{'control'} = 1;
					my $begin_doc = &PCE::Document::_get_current_nr;
					while ( $return == -1 ) {
						&PCE::Edit::_restore_positions;
						last if PCE::Document::_get_current_nr()
								== PCE::Document::_get_last_nr()
							and not $attr->{'auto_wrap'};
						&PCE::Document::Change::tab_right;
						&PCE::Edit::_save_positions;
						$return = &_find_first;
						last if &PCE::Document::_get_current_nr == $begin_doc;
					}
					$PCE::internal{'dialog'}{'control'} = 0;
					$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
						if $PCE::internal{'dialog'}{'search'}{'active'};
				}
			}
			_refresh_find_history($return) if $_ == 1;
			if ( $return == -1 ) { &PCE::Edit::_restore_positions; last; }
			else { _caret_2_sel_end(); &PCE::Edit::_let_caret_visible; }
		}
	}
}

sub find_first {
	my $menu_call = shift;
	my $ep = &PCE::App::STC::_get;
	my $attr = $PCE::config{'search'}{'attribute'};
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if ( _exist_find_item() ) {
		&PCE::Edit::_save_positions;
		if ($menu_call
		and $sel_begin != $sel_end
		and $sel_end - $sel_begin > $len ) {
			$attr->{'in'} = 'selection'
		}
		if ( $attr->{'in'} eq 'selection' ) {
			PCE::Edit::_goto_pos($sel_begin);
			$return = &_find_next;
			if ($return > -1 and $ep->GetCurrentPos + $len <= $sel_end) {
				&PCE::Edit::_let_caret_visible;
			} else {
				&PCE::Edit::_restore_positions;
				$return = -1;
			}
		} else {
			$return = &_find_first;
			if ( $attr->{'in'} eq 'open_docs'
			and ($sel_begin == $ep->GetSelectionStart or $return == -1 )) {
				$PCE::internal{'dialog'}{'control'} = 1;
				$return = -1;
				my $begin_doc = &PCE::Document::_get_current_nr;
				while ( $return == -1 ) {
					&PCE::Edit::_restore_positions;
					last if &PCE::Document::_get_current_nr == 0
						and not $attr->{'auto_wrap'};
					PCE::Document::Change::tab_left();
					&PCE::Edit::_save_positions;
					$return = &_find_first;
					last if ( &PCE::Document::_get_current_nr == $begin_doc );
				}
				$PCE::internal{'dialog'}{'control'} = 0;
				$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
					if $PCE::internal{'dialog'}{'search'}{'active'};
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				&PCE::Edit::_let_caret_visible;
			} else {
				&PCE::Edit::_restore_positions;
			}
		}
		_refresh_find_history($return);
	}
	$return;
}

sub find_last {
	my $menu_call = shift;
	my $ep = &PCE::App::STC::_get;
	my $attr = $PCE::config{'search'}{'attribute'};
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if (&_exist_find_item) {
		&PCE::Edit::_save_positions;
		if ($menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len) {
			$attr->{'in'} = 'selection';
		}
		if ( $attr->{'in'} eq 'selection' ) {
			PCE::Edit::_goto_pos($sel_end);
			$return = &_find_prev;
			if ($return > -1 and $ep->GetCurrentPos >= $sel_begin) {
				&PCE::Edit::_let_caret_visible;
			} else {
				&PCE::Edit::_restore_positions;
				$return = -1;
			}
		} else {
			$return = &_find_last;
			if ($attr->{'in'} eq 'open_docs'
				and ($sel_begin == $ep->GetSelectionStart or $return == -1)) {
				$PCE::internal{'dialog'}{'control'} = 1;
				$return = -1;
				my $begin_doc = &PCE::Document::_get_current_nr;
				while ( $return == -1 ) {
					&PCE::Edit::_restore_positions;
					last if PCE::Document::_get_current_nr()
							== PCE::Document::_get_last_nr()
						and not $attr->{'auto_wrap'};
					PCE::Document::Change::tab_right();
					&PCE::Edit::_save_positions;
					$return = &_find_last;
					last if ( &PCE::Document::_get_current_nr == $begin_doc );
				}
				$PCE::internal{'dialog'}{'control'} = 0;
				$PCE::internal{'dialog'}{'search'}{'pointer'}->Raise
					if $PCE::internal{'dialog'}{'search'}{'active'};
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				PCE::Edit::_let_caret_visible();
			} else {
				PCE::Edit::_restore_positions();
			}
		}
		&_refresh_find_history($return);
	}
	$return;
}

  # replace
sub replace_back {
	my $ep = PCE::App::STC::_get();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		_replace_selection();
		_refresh_replace_history();
		find_prev();
	}
}

sub replace_fore {
	my $ep = PCE::App::STC::_get();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		_replace_selection();
		_refresh_replace_history();
		find_next();
	}
}

sub replace_all {
	my $menu_call = shift;
	my $ep = &PCE::App::STC::_get;
	my ($sel_begin, $sel_end ) = $ep->GetSelection;
	my $line           = $ep->GetCurrentLine;
	my $len            = _exist_find_item();
	my $replace_string = get_replace_item();
	if ($len) {
		if (    $menu_call
		    and $sel_begin != $sel_end 
			and $sel_end - $sel_begin > $len ) {
			$PCE::config{'search'}{'attribute'}{'in'} = 'selection';
		}
		if ( $PCE::config{'search'}{'attribute'}{'in'} eq 'selection' ) {
			$ep->BeginUndoAction;
			$ep->GotoPos($sel_begin);
			while ( &_find_next > -1 ) {
				last if ( $ep->GetCurrentPos + $len >= $sel_end );
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( $PCE::config{'search'}{'attribute'}{'in'} eq 'document' ) {
			$ep->BeginUndoAction;
			$ep->GotoPos(0);
			while ( &_find_next > -1 ) {
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( $PCE::config{'search'}{'attribute'}{'in'} eq 'open_docs' ) {
			my $begin_doc = &PCE::Document::_get_current_nr;
			do {
				{
					&PCE::Edit::_save_positions;
					$ep->BeginUndoAction;
					$ep->GotoPos(0);
					while ( &_find_next > -1 ) {
						$ep->ReplaceSelection($replace_string);
					}
					$ep->EndUndoAction;
					&PCE::Edit::_restore_positions;
				}
			} until ( PCE::Document::Change::tab_right() == $begin_doc );
		}
		$ep->GotoLine($line);
		_refresh_replace_history;
		PCE::Edit::_keep_focus();
	}
}

sub replace_confirm {
	if (&_exist_find_item) {
		my $ep = PCE::App::STC::_get();
		my $attr = $PCE::config{'search'}{'attribute'};
		my $line = $ep->LineFromPosition( $ep->GetCurrentPos );
		my $len  = _exist_find_item();
		my $sel_begin = $ep->GetSelectionStart;
		my $sel_end   = $ep->GetSelectionEnd;
		my $answer    = wxYES;
		my $menu_call = shift;

		$attr->{'in'} = 'selection'
			if $menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len;

		if ($attr->{'in'} eq 'selection') {
			sniff_selection( $ep, $sel_begin, $sel_end, $len, $line );
		} elsif ($attr->{'in'} eq 'document') {
			sniff_selection( $ep, 0, $ep->GetTextLength, $len, $line );
		} elsif ($attr->{'in'} eq 'open_docs') {
			my $begin_doc = &PCE::Document::_get_current_nr;
			do {
				{
					next if $answer == wxCANCEL;
					&PCE::Edit::_save_positions;
					$answer = &sniff_selection( $ep, 0,
						$ep->GetTextLength, $len, $line );
					&PCE::Edit::_restore_positions;
				}
			} until ( PCE::Document::Change::tab_right() == $begin_doc );
		}
	}

	sub sniff_selection {
		my ( $ep, $sel_begin, $sel_end, $len, $line ) = @_;
		my $l10n = $PCE::localisation{'dialog'}{'search'}{'confirm'};
		my $answer;
		&PCE::Edit::_goto_pos($sel_begin);
		$ep->BeginUndoAction();
		while ( &_find_next > -1 ) {
			last if $ep->GetCurrentPos + $len >= $sel_end;
			&PCE::Edit::_let_caret_visible;
			$answer = PCE::Dialog::get_confirm_3
				(undef, $l10n->{'text'}, $l10n->{'title'}, 100, 100);
			last if $answer == wxCANCEL;
			if ($answer == wxYES) {&_replace_selection}
			else                  {$ep->SetCurrentPos( $ep->GetCurrentPos + 1 )}
		}
		$ep->EndUndoAction;
		&PCE::Edit::_goto_pos( $ep->PositionFromLine($line) );
		&PCE::Edit::_let_caret_visible;
		$answer;
	}
	_refresh_replace_history();
	PCE::Edit::_keep_focus();
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
	$self;
}

sub OnDropText {
	my ( $self, $x, $y, $text ) = @_;
	$self->{target}->SetValue( $text ) if $self->{target};
	$self->{kind} eq 'replace'
		? PCE::Edit::Search::set_replace_item($text)
		: PCE::Edit::Search::set_find_item($text);
	0; #dont skip event
}

1;
