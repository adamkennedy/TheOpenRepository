package PCE::Dialog::Exit;
$VERSION = '0.04';

use strict;
use Wx qw(
			wxDefaultPosition wxDefaultSize wxBOTH
			wxVERTICAL wxHORIZONTAL wxLEFT wxCENTER wxRIGHT wxTOP wxBOTTOM
			wxALIGN_LEFT wxALIGN_CENTER_VERTICAL wxLI_HORIZONTAL
			wxNO_FULL_REPAINT_ON_RESIZE wxCAPTION wxSTAY_ON_TOP
);
use Wx::Event qw( EVT_BUTTON EVT_CHECKBOX EVT_CLOSE );

sub save_on_exit {

	# checking settings if i should save or quit without question
	if    ( $PCE::config{'file'}{'save'}{'b4_quit'} eq '0' ) {                      return}
	elsif ( $PCE::config{'file'}{'save'}{'b4_quit'} eq '1' ) {&PCE::File::save_all; return}

	# count unsaved dacuments?
	my $unsaved_docs = 0;
	for ( 0 .. PCE::Document::_get_last_nr() ) {
		$unsaved_docs++ if $PCE::internal{'document'}{'open'}[$_]{'modified'}
	}

	# if so...
	if ($unsaved_docs) {
		my $localisation = $PCE::localisation{'dialog'}{'general'};
		my $dialog = $PCE::app{'dialog'}{'exit'} = Wx::Dialog->new(
			PCE::App::Window::_get(), -1,
			$PCE::localisation{'dialog'}{'file'}{'quit_unsaved'},
			[-1,-1], [-1,-1],
			wxNO_FULL_REPAINT_ON_RESIZE | wxCAPTION | wxSTAY_ON_TOP,
		);

		# starting dialog layout
		my $v_sizer      = Wx::BoxSizer->new(wxVERTICAL);
		my $h_sizer      = Wx::BoxSizer->new(wxHORIZONTAL);
		my $button_sizer = Wx::GridSizer->new( 1, 4, 0, 25 );
		my ( @temp_sizer, @check_boxes );
		my ( $border,     $b_border, $max_width ) = ( 10, 20, 0 );
		my ( $x_size,     $y_size );
		my ( $file_name,  $check_label );

		# generating checkbox list of unsaved files
		for ( 0 .. PCE::Document::_get_last_nr() ) {
			if ( $PCE::internal{'document'}{'open'}[$_]{'modified'} ) {
				$file_name = '';
				$file_name = $PCE::document{'open'}[$_]{'path'};
				if ($file_name) {$check_label = 1 + $_ . ' ' . $file_name}
				else {$check_label = 1+$_ . ' '
						. $PCE::localisation{'app'}{'tabs'}{'untitled'};
				}
				$check_boxes[$_] = Wx::CheckBox->new($dialog, -1, $check_label);
				$check_boxes[$_]->SetValue(1);
				$temp_sizer[$_] = Wx::BoxSizer->new(wxVERTICAL);
				$temp_sizer[$_]->Add($check_boxes[$_], 0,
					wxLEFT|wxALIGN_CENTER_VERTICAL, $border );
				$v_sizer->Add( $temp_sizer[$_], 0, wxTOP, $border );
				$temp_sizer[$_]->Fit($dialog);
				( $x_size, $y_size ) = $dialog->GetSizeWH;
				$max_width = $x_size if $x_size > $max_width;
			}
		}

		# seperator, label, buttons
		my $base_line = Wx::StaticLine->new( $dialog, -1, [-1,-1],[2000,2], wxLI_HORIZONTAL);
		my $save_label = Wx::StaticText->new($dialog, -1, $$localisation{'save'} . ' : ' );
		$dialog->{'save_all'} = Wx::Button->new($dialog, -1, $$localisation{'all'} );
		$dialog->{'save_sel'} = Wx::Button->new($dialog, -1, $$localisation{'selected'} );
		$dialog->{'save_none'} = Wx::Button->new($dialog, -1, $$localisation{'none'} );
		$dialog->{'cancel'} = Wx::Button->new($dialog, -1, $$localisation{'cancel'} );

		# events
		EVT_BUTTON( $dialog, $dialog->{'save_all'}, sub {&quit_dialog; &PCE::File::save_all} );
		EVT_BUTTON( $dialog, $dialog->{'save_sel'}, sub {&quit_dialog; save_selected(\@check_boxes)} );
		EVT_BUTTON( $dialog, $dialog->{'save_none'}, sub { quit_dialog() } );
		EVT_BUTTON( $dialog, $dialog->{'cancel'}, sub { &quit_dialog; $dialog->{'cancel'} = 1; } );
		EVT_CLOSE( $dialog, sub { quit_dialog() } );

		# assembling the fix bottom of dialog layout
		$h_sizer->Add( $save_label, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, $border );
		$h_sizer->Add( $dialog->{'save_all'}, 0, wxLEFT | wxALIGN_CENTER_VERTICAL,
			$border + $b_border );
		$h_sizer->Add( $dialog->{'save_sel'}, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, $b_border );
		$h_sizer->Add( $dialog->{'save_none'}, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, $b_border );
		$h_sizer->Add( $dialog->{'cancel'}, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, $b_border );

		$v_sizer->Add( $base_line, 0, wxTOP | wxCENTER, $border );
		$v_sizer->Add( $h_sizer, 0, wxTOP, $border );

		# figuring dialog size
		$dialog->SetSizer($v_sizer);
		$v_sizer->Fit($dialog);
		( $x_size, $y_size ) = $dialog->GetSizeWH;
		$h_sizer->Fit($dialog);
		( $x_size, ) = $dialog->GetSizeWH;
		$max_width = $x_size if ( $x_size > $max_width );
		$dialog->SetSize( $max_width + $b_border, $y_size + $border );

		# go
		$dialog->SetAutoLayout(1);
		$dialog->CenterOnScreen;
		$dialog->ShowModal;
		return 'cancel' if $dialog->{'cancel'} == 1;
	}
}

# internal subs
################
sub save_selected {
	my @check_boxes = @{ shift; };
	my $doc_nr = &PCE::Document::_get_current_nr;
	for ( 0 .. $#check_boxes ) {
		if ( ref $check_boxes[$_] ne '' ) {
			if ( $check_boxes[$_]->GetValue ) {
				PCE::Document::Internal::change_pointer($_);
				&PCE::File::save_current;
			}
		}
	}
	PCE::Document::Change::to_number($doc_nr);
}

sub quit_dialog {
	my ( $win, $event ) = @_;
	$PCE::app{'dialog'}{'exit'}->Destroy;
}

1;
