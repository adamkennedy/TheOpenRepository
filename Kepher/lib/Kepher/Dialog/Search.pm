package KEPHER::Dialog::Search;
$VERSION = '0.22';

use strict;
use Wx qw( wxDefaultPosition wxDefaultSize  wxVERTICAL wxHORIZONTAL 
	wxLEFT wxRIGHT wxTOP wxBOTTOM wxCENTER wxGROW wxEXPAND wxBOTH
	wxALIGN_LEFT wxALIGN_CENTRE wxALIGN_CENTER_VERTICAL wxALIGN_CENTER_HORIZONTAL
	wxSYSTEM_MENU wxCAPTION wxDIALOG_NO_PARENT wxSTAY_ON_TOP wxNO_FULL_REPAINT_ON_RESIZE
	wxSIMPLE_BORDER wxRAISED_BORDER wxNO_BORDER wxRESIZE_BORDER
	wxCLOSE_BOX wxMINIMIZE_BOX wxFRAME_NO_TASKBAR
	wxTHICK_FRAME wxTAB_TRAVERSAL wxCLIP_CHILDREN  wxCHK_2STATE  wxRA_SPECIFY_COLS
	wxTE_PROCESS_ENTER wxTE_LEFT  wxLI_HORIZONTAL   wxBU_EXACTFIT  wxCB_DROPDOWN
	wxBITMAP_TYPE_XPM
);

use Wx::Event qw(
	EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE 
	EVT_CHAR EVT_TEXT_ENTER EVT_ENTER_WINDOW
);
##########################
sub find {
	my $d         = get_dialog();
	my $selection = KEPHER::App::STC::_get()->GetSelectedText;
	if ( length $selection > 0 and not $d->{'selection_radio'}->GetValue ) {
		KEPHER::Edit::Search::set_find_item( $selection );
		$d->{'find_input'}->SetValue( $selection );
	}
	$d->{'replace_input'}->SetValue( KEPHER::Edit::Search::get_replace_item() );
	Wx::Window::SetFocus( $d->{'find_input'} );
}
##########################
sub replace {
	my $d = get_dialog();
	my $selection = KEPHER::App::STC::_get()->GetSelectedText;
	if ( length $selection > 0 and not $d->{'selection_radio'}->GetValue ) {
		KEPHER::Edit::Search::set_replace_item( $selection );
		$d->{'replace_input'}->SetValue( $selection );
	}
	$d->{'find_input'}->SetValue( $selection );
	Wx::Window::SetFocus( $d->{'replace_input'} );
}
##########################
sub get_dialog {
	if ( not $KEPHER::internal{'dialog'}{'search'}{'active'} ) {

		# prepare some internal var and for better handling
		my $sci_frame       = &KEPHER::App::STC::_get;
		my $attr            = $KEPHER::config{'search'}{'attribute'};
		my $dsettings       = $KEPHER::config{'dialog'}{'search'};
		my $label           = $KEPHER::localisation{'dialog'}{'search'}{'label'};
		my $hint            = $KEPHER::localisation{'dialog'}{'search'}{'hint'};
		my @find_history    = ();
		my @replace_history = ();
		my $ico_dir = $KEPHER::internal{path}{config}.$KEPHER::config{app}{iconset_path};
		my $win_style = wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
			| wxMINIMIZE_BOX | wxCLOSE_BOX;
		$win_style |= wxSTAY_ON_TOP if $KEPHER::config{'app'}{'window'}{'stay_on_top'};
		$dsettings->{'position_x'} = 10 if $dsettings->{'position_x'} < 0;
		$dsettings->{'position_y'} = 10 if $dsettings->{'position_y'} < 0;
		if ( $KEPHER::config{'search'}{'history'}{'use'} ) {
			@find_history = @{ $KEPHER::config{'search'}{'history'}{'find_item'} };
			@replace_history = @{ $KEPHER::config{'search'}{'history'}{'replace_item'} };
		}

		# init search and replace dialog and release
		KEPHER::Edit::Search::_refresh_search_flags();
		$KEPHER::internal{'dialog'}{'search'}{'active'} = 1;
		$KEPHER::internal{'dialog'}{'active'}++;

		# make dialog window and main panel
		my $d = $KEPHER::app{'dialog'}{'search'} = Wx::Frame->new( 
			KEPHER::App::Window::_get(), -1, 
			$KEPHER::localisation{'dialog'}{'search'}{'title'},
			[ $dsettings->{'position_x'}, $dsettings->{'position_y'} ],
			[ 436                       , 268                   ], $win_style );
		KEPHER::App::Window::load_icon( $d, 'config/icon/app/find.ico' );
		my $panel = Wx::Panel->new( $d, -1 );

		# input boxes with labels
		$d->{'find_label'} = Wx::StaticText->new($panel, -1, $label->{'search_for'} );
		$d->{'replace_label'} = Wx::StaticText->new($panel, -1, $label->{'replace_with'} );
		$d->{'find_input'} = Wx::ComboBox->new($panel, -1, '', [-1,-1], [324,22], [@find_history],);
		$d->{'find_input'}->SetDropTarget( SearchInputTarget->new($d->{'find_input'}, 'find'));
		$d->{'replace_input'} = Wx::ComboBox->new($panel, -1, '', [-1,-1], [324,22], [@replace_history],);
		$d->{'replace_input'}->SetDropTarget( SearchInputTarget->new($d->{'replace_input'}, 'replace'));
		$d->{'sep_line'} = Wx::StaticLine->new($panel, -1, [0,0], [420,1], wxLI_HORIZONTAL,);

		# search attributes checkboxes
		$d->{'inc_box'} = Wx::CheckBox->new($panel, -1, $label->{'incremental'});
		$d->{'case_box'} = Wx::CheckBox->new($panel, -1, $label->{'case'});
		$d->{'begin_box'} = Wx::CheckBox->new($panel, -1, $label->{'word_begin'});
		$d->{'word_box'} = Wx::CheckBox->new($panel, -1, $label->{'whole_word'});
		$d->{'regex_box'} = Wx::CheckBox->new($panel, -1, $label->{'regex'});
		$d->{'wrap_box'} = Wx::CheckBox->new($panel, -1, $label->{'auto_wrap'});
		$d->{'inc_box'}->SetValue( $attr->{'incremental'} );
		$d->{'case_box'}->SetValue( $attr->{'match_case'} );
		$d->{'begin_box'}->SetValue( $attr->{'match_word_begin'} );
		$d->{'word_box'}->SetValue( $attr->{'match_whole_word'} );
		$d->{'regex_box'}->SetValue( $attr->{'match_regex'} );
		$d->{'wrap_box'}->SetValue( $attr->{'auto_wrap'} );

		# range radio group
		my $range_box = Wx::StaticBox->new($panel, -1, $label->{'search_in'},
			[-1,-1], [-1,-1], wxSIMPLE_BORDER | wxRAISED_BORDER,
		);
		$d->{'selection_radio'} = Wx::RadioButton->new($panel, -1, $label->{'selection'});
		$d->{'document_radio'} = Wx::RadioButton->new($panel, -1, $label->{'document'} );
		$d->{'all_open_radio'} = Wx::RadioButton->new($panel, -1, $label->{'open_documents'} );
################### disable

		# buttons
		$d->{'replace_back'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'replace_previous.xpm', wxBITMAP_TYPE_XPM) );
		$d->{'replace_fore'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'replace_next.xpm', wxBITMAP_TYPE_XPM) );
		$d->{'backward_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_previous.xpm', wxBITMAP_TYPE_XPM) );
		$d->{'foreward_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_next.xpm', wxBITMAP_TYPE_XPM ) );
		$d->{'fast_back_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_fast_backward.xpm', wxBITMAP_TYPE_XPM) );
		$d->{'fast_fore_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_fast_forward.xpm', wxBITMAP_TYPE_XPM) );
		$d->{'first_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_first.xpm', wxBITMAP_TYPE_XPM ) );
		$d->{'last_button'} = Wx::BitmapButton->new($panel, -1,
			Wx::Bitmap->new( $ico_dir . 'go_last.xpm', wxBITMAP_TYPE_XPM ) );
		$d->{'search_button'} = Wx::Button->new($panel, -1, $label->{'search'} );
		$d->{'replace_button'} = Wx::Button->new($panel, -1, $label->{'replace_all'} );
		$d->{'confirm_button'} = Wx::Button->new($panel, -1, $label->{'with_confirmation'} );
		$d->{'close_button'} = Wx::Button->new($panel, -1,
			$KEPHER::localisation{'dialog'}{'general'}{'close'} );

		#tooltips / hints
		if ( $dsettings->{'tooltips'} ) {
			$d->{'foreward_button'}->SetToolTip( $hint->{'forward'});
			$d->{'backward_button'}->SetToolTip( $hint->{'backward'});
			$d->{'fast_fore_button'}->SetToolTip( $hint->{'fast_forward'});
			$d->{'fast_back_button'}->SetToolTip( $hint->{'fast_backward'});
			$d->{'first_button'}->SetToolTip( $hint->{'document_start'});
			$d->{'last_button'}->SetToolTip( $hint->{'document_end'});
			$d->{'replace_fore'}->SetToolTip( $hint->{'replace_forward'});
			$d->{'replace_back'}->SetToolTip( $hint->{'replace_backward'});
			$d->{'case_box'}->SetToolTip( $hint->{'match_case'});
			$d->{'begin_box'}->SetToolTip( $hint->{'match_word_begin'});
			$d->{'word_box'}->SetToolTip( $hint->{'match_whole_word'});
			$d->{'regex_box'}->SetToolTip( $hint->{'match_regex'});
			$d->{'wrap_box'}->SetToolTip( $hint->{'auto_wrap'});
			$d->{'inc_box'}->SetToolTip( $hint->{'incremental'});
		}

		# eventhandling
		#EVT_TEXT_ENTER($d,$d->{'find_input'},   \&refresh_find_history);
		#EVT_TEXT_ENTER($d,$d->{'replace_input'},\&refresh_replace_history);
		EVT_KEY_DOWN($d->{'find_input'},       \&find_input_keyfilter );
		EVT_KEY_DOWN($d->{'replace_input'},    \&replace_input_keyfilter );
		EVT_TEXT($d, $d->{'find_input'},       \&incremental_search );
		EVT_TEXT($d, $d->{'replace_input'}, sub {
			KEPHER::Edit::Search::set_replace_item( $d->{'replace_input'}->GetValue)});
		EVT_CHECKBOX($d, $d->{'case_box'}, sub {
				$$attr{'match_case'} = $d->{'case_box'}->GetValue;
				KEPHER::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{'begin_box'}, sub {
				$$attr{'match_word_begin'} = $d->{'begin_box'}->GetValue;
				KEPHER::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{'word_box'}, sub {
				$$attr{'match_whole_word'} = $d->{'word_box'}->GetValue;
				KEPHER::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{'regex_box'}, sub {
				$$attr{'match_regex'} = $d->{'regex_box'}->GetValue;
				KEPHER::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{'wrap_box'}, sub {
				$$attr{'auto_wrap'} = $d->{'wrap_box'}->GetValue;
		} );
		EVT_CHECKBOX($d, $d->{'inc_box'}, sub {
				$$attr{'incremental'} = $d->{'inc_box'}->GetValue;
		} );
		EVT_RADIOBUTTON($d, $d->{'selection_radio'}, sub {$attr->{'in'} = 'selection'});
		EVT_RADIOBUTTON($d, $d->{'document_radio'}, sub {$attr->{'in'} = 'document'});
		EVT_RADIOBUTTON($d, $d->{'all_open_radio'}, sub {$attr->{'in'} = 'open_docs'});
		EVT_BUTTON($d, $d->{'foreward_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::find_next();
		} );
		EVT_BUTTON($d, $d->{'backward_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::find_prev();
		} );
		EVT_BUTTON($d, $d->{'fast_fore_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::fast_fore();
		} );
		EVT_BUTTON($d, $d->{'fast_back_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::fast_back();
		} );
		EVT_BUTTON($d, $d->{'first_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::find_first();
		} );
		EVT_BUTTON($d, $d->{'last_button'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::find_last();
		} );
		EVT_BUTTON($d, $d->{'replace_fore'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::replace_fore();
		} );
		EVT_BUTTON($d, $d->{'replace_back'}, sub {
				&no_sel_range;
				KEPHER::Edit::Search::replace_back();
		} );
		EVT_BUTTON($d, $d->{'search_button'},  sub{ &KEPHER::Edit::Search::find_first } );
		EVT_BUTTON($d, $d->{'replace_button'}, sub{ &KEPHER::Edit::Search::replace_all } );
		EVT_BUTTON($d, $d->{'confirm_button'}, sub{ &KEPHER::Edit::Search::replace_confirm } );
		EVT_BUTTON($d, $d->{'close_button'},   sub{ shift->Close() } );

		EVT_CLOSE( $d, \&quit_search_dialog );
	 #EVT_CHAR
	 #EVT_COMMAND_TEXT_ENTER($d->{'find_input'},sub {start_search($d);}});
	 #EVT_KEY_DOWN($d->{'foreward_button'}, \&foreward_keyfilter);
	 #EVT_KEY_DOWN($d->{'backward_button'}, \&backward_keyfilter);
	 #EVT_KEY_DOWN($d->{'fast_fore_button'},\&fast_fore_keyfilter);
	 #EVT_KEY_DOWN($d->{'fast_back_button'},\&fast_back_keyfilter);
	 #EVT_KEY_DOWN($d->{'first_button'},    \&first_keyfilter);
	 #EVT_KEY_DOWN($d->{'last_button'},     \&last_keyfilter);
	 #EVT_KEY_DOWN($d->{'replace_fore'},    \&replace_fore_keyfilter);
	 #EVT_KEY_DOWN($d->{'replace_back'},    \&replace_back_keyfilter);
	 #EVT_KEY_DOWN($d->{'range_group'},\&range_keyfilter);

		# detecting and selecting search range
		if ( $sci_frame->LineFromPosition( $sci_frame->GetSelectionStart )
			!= $sci_frame->LineFromPosition( $sci_frame->GetSelectionEnd ) ) {
			$KEPHER::config{'search'}{'attribute'}{'in'} = 'selection';
			$d->{'selection_radio'}->SetValue(1);
			} elsif ( $KEPHER::config{'search'}{'attribute'}{'in'} eq 'open_docs' ) {
			$d->{'all_open_radio'}->SetValue(1);
			} else {
			$KEPHER::config{'search'}{'attribute'}{'in'} = 'document';
			$d->{'document_radio'}->SetValue(1);
		}

		# asembling
		my $option_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$option_sizer->Add( $d->{'inc_box'},   0, wxTOP,  0 );
		$option_sizer->Add( $d->{'case_box'},  0, wxTOP, 15 );
		$option_sizer->Add( $d->{'begin_box'}, 0, wxTOP,  5 );
		$option_sizer->Add( $d->{'word_box'},  0, wxTOP,  5 );
		$option_sizer->Add( $d->{'regex_box'}, 0, wxTOP,  5 );

		my $rbz = Wx::StaticBoxSizer->new( $range_box, wxVERTICAL );
		$rbz->Add( $d->{'selection_radio'}, 1, wxTOP, 5 );
		$rbz->Add( $d->{'document_radio'},  1, wxTOP, 5 );
		$rbz->Add( $d->{'all_open_radio'},  1, wxTOP, 5 );
		my $range_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$range_sizer->Add( $d->{'wrap_box'}, 0, wxTOP, 0 );
		$range_sizer->Add( $rbz, 0, wxGROW | wxTOP, 10 );

		my $pad_grid = Wx::GridBagSizer->new( 0, 0 );
		$pad_grid->Add( $d->{'replace_back'}, Wx::GBPosition->new(0,0), Wx::GBSpan->new(1,1), wxRIGHT, 0);
		$pad_grid->Add( $d->{'replace_fore'}, Wx::GBPosition->new(0,1), Wx::GBSpan->new(1,1), wxLEFT, 0);
		$pad_grid->Add( $d->{'backward_button'}, Wx::GBPosition->new(1,0), Wx::GBSpan->new(1,1), wxTOP, 5);
		$pad_grid->Add( $d->{'foreward_button'}, Wx::GBPosition->new(1,1), Wx::GBSpan->new(1,1), wxTOP, 5);
		$pad_grid->Add( $d->{'fast_back_button'}, Wx::GBPosition->new(2,0), Wx::GBSpan->new(1,1), wxRIGHT, 0);
		$pad_grid->Add( $d->{'fast_fore_button'}, Wx::GBPosition->new(2,1), Wx::GBSpan->new(1,1), wxLEFT, 0);
		$pad_grid->Add( $d->{'first_button'}, Wx::GBPosition->new(3,0), Wx::GBSpan->new(1,1), wxRIGHT, 0);
		$pad_grid->Add( $d->{'last_button'}, Wx::GBPosition->new(3,1), Wx::GBSpan->new(1,1), wxLEFT, 0);

		my $button_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$button_sizer->Add( $d->{'search_button'},  0, wxLEFT, 10 );
		$button_sizer->Add( $d->{'replace_button'}, 0, wxLEFT, 10 );
		$button_sizer->Add( $d->{'confirm_button'}, 0, wxLEFT, 10 );
		$button_sizer->Add( $d->{'close_button'},   0, wxLEFT, 52 );

		my $b_grid = Wx::GridBagSizer->new( 0, 10 );
		$b_grid->Add( $d->{'find_label'}, Wx::GBPosition->new(0,0),
			Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 10);
		$b_grid->Add( $d->{'replace_label'}, Wx::GBPosition->new(1,0),
			Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 10);
		$b_grid->Add($d->{'find_input'}, Wx::GBPosition->new(0,1), Wx::GBSpan->new(1,4), wxTOP , 5);
		$b_grid->Add($d->{'replace_input'}, Wx::GBPosition->new(1,1), Wx::GBSpan->new(1,4), wxTOP , 5);
		$b_grid->Add( $option_sizer, Wx::GBPosition->new(2,1), Wx::GBSpan->new(1,1), wxTOP, 12);
		$b_grid->Add( $range_sizer,  Wx::GBPosition->new(2,2), Wx::GBSpan->new(1,1), wxTOP | wxLEFT, 12);
		$b_grid->Add( $pad_grid,  Wx::GBPosition->new(2,3), Wx::GBSpan->new(1,1), wxTOP | wxLEFT, 12);

		my $d_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$d_sizer->Add($b_grid,          0, wxTOP, 7);
		$d_sizer->Add($d->{'sep_line'}, 0, wxTOP | wxALIGN_CENTER_HORIZONTAL, 15);
		$d_sizer->Add($button_sizer,    0, wxTOP , 12);

		$panel->SetSizer($d_sizer);
		$panel->SetAutoLayout(1);

		# go
		$d->Show(1);
		return $d;
	} else {
		my $d = $KEPHER::app{'dialog'}{'search'};
		$d->Iconize(0);
		$d->Raise;
		return $d;
	}
}
##########################
# dialog event functions


sub refresh_replace_history {
	return unless $KEPHER::config{'search'}{'history'}{'use'};
	my $dialog = $KEPHER::app{'dialog'}{'search'};
	my $cb     = $dialog->{'replace_input'};
	my $value  = $cb->GetValue;
	$KEPHER::internal{'dialog'}{'search'}{'control'} = 1;
	if (KEPHER::Edit::Search::get_replace_item() ne $value){
		KEPHER::Edit::Search::set_replace_item($value);
		$cb->Delete(0) for 0 .. $cb->GetCount;
		$cb->Append($_) for @{ $KEPHER::config{'search'}{'history'}{'replace_item'} };
		$cb->SetValue($value);
		$cb->SetInsertionPointEnd;
	}
	$KEPHER::internal{'dialog'}{'search'}{'control'} = 0;
}

sub no_sel_range {
	my $dialog = $KEPHER::app{'dialog'}{'search'};
	if ( $dialog->{'selection_radio'}->GetValue ) {
		$dialog->{'document_radio'}->SetValue(1);
		$KEPHER::config{'search'}{'attribute'}{'in'} = 'document';
	}
	
	#$dialog->Refresh;
	#$dialog->Layout();
}

#
sub find_input_keyfilter {
	my ( $input, $event ) = @_;
	my $dialog   = $input->GetParent->GetParent;
	my $wx_frame = $dialog->GetParent;
	my $key_code = $event->GetKeyCode;
	if ($key_code == 13) {
		no_sel_range();
		if ($event->ControlDown) {
			&KEPHER::Edit::Search::find_first;
			$dialog->Close;
		} elsif ( $event->ShiftDown ) {
			&KEPHER::Edit::Search::find_prev;
		} else {
			&KEPHER::Edit::Search::find_next;
		}
		refresh_find_history();
	}
	elsif ($key_code == 27) { $dialog->Close }
	$event->Skip;
}

sub refresh_find_history {
	return unless $KEPHER::config{'search'}{'history'}{'use'};
	my $dialog = $KEPHER::app{'dialog'}{'search'};
	my $cb     = $dialog->{'find_input'};
	my $value  = $cb->GetValue;
	$KEPHER::internal{'dialog'}{'search'}{'control'} = 1;
	if (KEPHER::Edit::Search::get_find_item() ne $value){
		KEPHER::Edit::Search::set_find_item($value);
		$cb->Delete(0)  for 0 .. $cb->GetCount;
		KEPHER::App::get_ref->Yield();
		$cb->Append($_) for @{ $KEPHER::config{'search'}{'history'}{'find_item'} };
		$cb->SetValue($value);
		$cb->SetInsertionPointEnd;
	}
	$KEPHER::internal{'dialog'}{'search'}{'control'} = 0;
}

sub incremental_search {
	my $dialog = $KEPHER::app{'dialog'}{'search'};
	if ( $KEPHER::config{'search'}{'attribute'}{'incremental'}
		and not $KEPHER::internal{'dialog'}{'search'}{'control'} ) {
		my $inputbox = $dialog->{'find_input'};
		KEPHER::Edit::Search::set_find_item($inputbox->GetValue);

		if (KEPHER::Edit::Search::first_increment) {
			$inputbox->SetForegroundColour(	Wx::Colour->new( 0x00, 0x00, 0x55 ) );
			$inputbox->SetBackgroundColour(	Wx::Colour->new( 0xff, 0xff, 0xff ) );
		} else {
			$inputbox->SetForegroundColour( Wx::Colour->new( 0xff, 0x33, 0x33 ) );
			$inputbox->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
		}
		$inputbox->Refresh;
	}
}

sub replace_input_keyfilter {
	my ($input, $event) = @_;
	my ($dialog, $key_code) =($input->GetParent->GetParent, $event->GetKeyCode);
	if ($key_code == 13 ) {
		if ( $event->ControlDown ) {
			KEPHER::Edit::Search::replace_all;
			$dialog->Close;
		} elsif ( $event->AltDown ) { replace_confirm($dialog) }
		else                        { KEPHER::Edit::Search::replace_all() }
		refresh_find_history();
	}
	if ( $key_code == 27 ) { $dialog->Close }
	$event->Skip;
}

sub foreward_keyfilter {
	my ( $win, $event ) = ( shift->GetParent, shift );
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	if ($key_code == 13 or $key_code == 32) {
		KEPHER::Edit::Search::find_next()
	}
	if ( $key_code == 27 ) { $win->Close }
	if ( $key_code == 316 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
	if ( $key_code == 317 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
	if ( $key_code == 318 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
	if ( $key_code == 319 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
	$event->Skip;
}

sub backward_keyfilter {
	my ( $win, $event ) = ( shift->GetParent, shift );
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	if ($key_code == 13 or $key_code == 32) {
		KEPHER::Edit::Search::find_prev()
	}
	if ( $key_code ==  27 ) { $win->Close }
	if ( $key_code == 316 ) { Wx::Window::SetFocus( $win->{'foreward_button'} ) }
	if ( $key_code == 317 ) { Wx::Window::SetFocus( $win->{'replace_back'} ) }
	if ( $key_code == 318 ) { Wx::Window::SetFocus( $win->{'replace_button'} ) }
	if ( $key_code == 319 ) { Wx::Window::SetFocus( $win->{'fast_back_button'} ) }
}

sub fast_fore_keyfilter {
	my ( $win, $event ) = ( shift->GetParent, shift );
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	if ($key_code == 13 or $key_code == 32) {
		KEPHER::Edit::Search::fast_fore()
	}
	if ( $key_code == 27 )  { $win->Close }
	if ( $key_code == 316 ) { Wx::Window::SetFocus( $win->{'range_group'} ) }
	if ( $key_code == 317 ) { Wx::Window::SetFocus( $win->{'foreward_button'} ) }
	if ( $key_code == 318 ) { Wx::Window::SetFocus( $win->{'fast_back_button'} ) }
	if ( $key_code == 319 ) { Wx::Window::SetFocus( $win->{'first_button'} ) }
}

sub fast_back_keyfilter {
	my ( $win, $event ) = ( shift->GetParent, shift );
	my $key_code = $event->GetKeyCode();
	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	if ($key_code == 13 or $key_code == 32) {
		KEPHER::Edit::Search::fast_back( $win->GetParent() );
	}
	if ( $key_code == 27 ) { $win->Close }
	if ( $key_code == 316 ) { Wx::Window::SetFocus( $win->{'fast_fore_button'} ) }
	if ( $key_code == 317 ) { Wx::Window::SetFocus( $win->{'backward_button'} ) }
	if ( $key_code == 318 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
	if ( $key_code == 319 ) { Wx::Window::SetFocus( $win->{'last_button'} ) }
}

sub first_keyfilter {
	my ( $win, $event ) = ( shift->GetParent, shift );
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	KEPHER::Edit::Search::find_first() if $key_code == 13 or $key_code == 32;
	if ( $key_code ==  27 ) { $win->Close }
	if ( $key_code == 316 ) { Wx::Window::SetFocus( $win->{'range_group'} ) }
	if ( $key_code == 317 ) { Wx::Window::SetFocus( $win->{'fast_fore_button'} ) }
	if ( $key_code == 318 ) { Wx::Window::SetFocus( $win->{'last_button'} ) }
	if ( $key_code == 319 ) { Wx::Window::SetFocus( $win->{'close_button'} ) }
}

sub last_keyfilter {
	my ($win, $event) = (shift->GetParent, shift);
	my $key_code = $event->GetKeyCode;

	KEPHER::Edit::Search::find_last() if $key_code == 13 or $key_code == 32;
	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	elsif ($key_code ==  27) {$win->Close }
	elsif ($key_code == 316) {Wx::Window::SetFocus( $win->{'first_button'} )}
	elsif ($key_code == 317) {Wx::Window::SetFocus( $win->{'fast_back_button'} )}
	elsif ($key_code == 318) {Wx::Window::SetFocus( $win->{'close_button'} )}
	elsif ($key_code == 319) {Wx::Window::SetFocus( $win->{'close_button'} )}
}

sub replace_fore_keyfilter {
	my ($win, $event) = (shift->GetParent, shift);
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
			? Wx::Window::SetFocus($win->{'close_button'})
			: Wx::Window::SetFocus($win->{'range_group'});
	}
	elsif ( $key_code ==  13 ) {KEPHER::Edit::Search::replace_fore()}
	elsif ( $key_code ==  27 ) {$win->Close}
	elsif ( $key_code ==  32 ) {KEPHER::Edit::Search::replace_fore()}
	elsif ( $key_code == 316 ) {Wx::Window::SetFocus( $win->{'range_group'} )}
	elsif ( $key_code == 317 ) {Wx::Window::SetFocus( $win->{'replace_button'} )}
	elsif ( $key_code == 318 ) {Wx::Window::SetFocus( $win->{'replace_back'} )}
	elsif ( $key_code == 319 ) {Wx::Window::SetFocus( $win->{'foreward_button'} )}
}

sub replace_back_keyfilter {
	my ($win, $event) = (shift->GetParent, shift);
	my $key_code = $event->GetKeyCode;

	if ( $key_code == 9 ) {
		$event->ShiftDown
		? Wx::Window::SetFocus($win->{'close_button'})
		: Wx::Window::SetFocus($win->{'range_group'});
	}
	KEPHER::Edit::Search::replace_back() if $key_code == 13 or $key_code == 32;

	if ( $key_code ==  27 ) {$win->Close}
	if ( $key_code == 316 ) {Wx::Window::SetFocus( $win->{'replace_fore'} )}
	if ( $key_code == 317 ) {Wx::Window::SetFocus( $win->{'replace_button'} )}
	if ( $key_code == 318 ) {Wx::Window::SetFocus( $win->{'replace_button'} )}
	if ( $key_code == 319 ) {Wx::Window::SetFocus( $win->{'backward_button'} )}
}


sub replace_all { KEPHER::Edit::Search::replace_all() }
sub replace_confirm { KEPHER::Edit::Search::replace_confirm() }

sub quit_search_dialog {
	my ( $win, $event ) = @_;
	my $config = $KEPHER::config{'dialog'}{'search'};
	($config->{'position_x'}, $config->{'position_y'} ) = $win->GetPositionXY
		if $config->{'save_position'} == 1;

	$KEPHER::internal{'dialog'}{'search'}{'active'} = 0;
	$KEPHER::internal{'dialog'}{'active'}--;
	$win->Destroy();
}
#######################
1;
