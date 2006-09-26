package Kephra::Dialog::Config;
$VERSION = '0.15';

use strict;
use Wx
	qw( wxDefaultPosition wxDefaultSize   wxVERTICAL wxHORIZONTAL wxLEFT wxTOP wxBOTTOM wxGROW wxEXPAND
	wxOK wxYES wxYES_NO wxNO wxCANCEL wxID_CANCEL   wxSAVE wxOPEN   wxALIGN_LEFT wxALIGN_CENTRE
	wxSYSTEM_MENU wxCAPTION wxDIALOG_NO_PARENT wxSTAY_ON_TOP wxNO_FULL_REPAINT_ON_RESIZE
	wxSIMPLE_BORDER wxRAISED_BORDER wxNO_BORDER wxRESIZE_BORDER
	wxCLOSE_BOX wxMINIMIZE_BOX wxBOTH wxFRAME_NO_TASKBAR
	wxTHICK_FRAME wxTAB_TRAVERSAL wxCLIP_CHILDREN  wxCHK_2STATE  wxRA_SPECIFY_COLS
	wxLI_HORIZONTAL wxLIST_FORMAT_LEFT   wxLC_LIST   wxTE_LEFT  wxBU_EXACTFIT  wxCB_DROPDOWN  wxWANTS_CHARS
	wxICON_INFORMATION wxICON_WARNING wxICON_QUESTION wxBITMAP_TYPE_XPM  wxWHITE);

use Wx::Event
	qw(EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE);

sub main {
	my $frame = $Kephra::temp{'mainframe'};
	if ( !$Kephra::temp{'config'}{'dialog_active'}
		|| $Kephra::temp{'config'}{'dialog_active'} == 0 ) {

		# init search and replace dialog
		my $ico_dir = $Kephra::temp{path}{config} . 'icon/set/jenne/';
		$Kephra::temp{'config'}{'dialog_active'} = 1;

		# making window & main design
		my $config_win = Wx::Frame->new(
			$frame, -1,
			' ' . $Kephra::localisation{'dialog'}{'settings'}{'title'},
			[            $Kephra::config{'dialog'}{'config'}{'position_x'},
				$Kephra::config{'dialog'}{'config'}{'position_y'}
			],
			[ 440, 460 ],
			wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
				| wxMINIMIZE_BOX | wxCLOSE_BOX,
		);
		&Kephra::App::Window::load_icon( $config_win,
			$Kephra::config{'main'}{'icon'} );

		my $config_main
			= Wx::Panel->new( $config_win, -1, [ 0, 0 ], [ 480, 460 ],, );
		my $config_menu
			= Wx::Panel->new( $config_main, -1, [ 10, 10 ], [ 69, 362 ],, );
		$config_menu->SetBackgroundColour(wxWHITE);
		my $menu_border = Wx::StaticBox->new(
			$config_main, -1, '',
			[ 10, 4 ],
			[ 71, 370 ],
			wxSIMPLE_BORDER | wxRAISED_BORDER,
		);

		# construction left main menu
		my $program_panel_button = Wx::BitmapButton->new(
			$config_menu,
			-1,
			Wx::Bitmap->new(
				$ico_dir . 'config_mode_full.xpm',
				wxBITMAP_TYPE_XPM
			),
			[ 11, 6 ],
			[ 48, 48 ],
			,
			,
		);
		my $edit_panel_button = Wx::BitmapButton->new(
			$config_menu,
			-1,
			Wx::Bitmap->new(
				$ico_dir . 'config_mode_full.xpm',
				wxBITMAP_TYPE_XPM
			),
			[ 11, 78 ],
			[ 48, 48 ],
			,
			,
		);
		my $files_panel_button = Wx::BitmapButton->new(
			$config_menu,
			-1,
			Wx::Bitmap->new(
				$ico_dir . 'config_mode_full.xpm',
				wxBITMAP_TYPE_XPM
			),
			[ 11, 150 ],
			[ 48, 48 ],
			,
			,
		);
		my $program_label = Wx::StaticText->new(
			$config_menu, -1,
			$Kephra::localisation{'dialog'}{'settings'}{'panel'}{'general'},
			[ 0,  56 ],
			[ 70, 14 ],
			wxALIGN_CENTRE,
		);
		my $edit_label = Wx::StaticText->new(
			$config_menu, -1,
			$Kephra::localisation{'dialog'}{'settings'}{'panel'}{'edit'},
			[ 0,  129 ],
			[ 70, 14 ],
			wxALIGN_CENTRE,
		);
		my $file_label = Wx::StaticText->new(
			$config_menu, -1,
			$Kephra::localisation{'dialog'}{'settings'}{'panel'}{'files'},
			[ 0,  201 ],
			[ 70, 14 ],
			wxALIGN_CENTRE,
		);

		#
		$config_win->{'apply_button'} = Wx::Button->new(
			$config_main, -1,
			$Kephra::localisation{'dialog'}{'general'}{'apply'},
			[ 83, 392 ],
			[ 80, -1 ],
			,,
		);
		$config_win->{'save_button'} = Wx::Button->new(
			$config_main, -1,
			$Kephra::localisation{'dialog'}{'general'}{'save'},
			[ 172, 392 ],
			[ 76,  -1 ],
			,,
		);
		$config_win->{'restore_button'} = Wx::Button->new(
			$config_main, -1,
			$Kephra::localisation{'dialog'}{'general'}{'restore'},
			[ 257, 392 ],
			[ 80,  -1 ],
			,,
		);
		$config_win->{'cancel_button'} = Wx::Button->new(
			$config_main, -1,
			$Kephra::localisation{'dialog'}{'general'}{'cancel'},
			[ 346, 392 ],
			[ 76,  -1 ],
			,,
		);

		# release
		$config_win->Show(1);

		# events
		EVT_BUTTON(
			$config_win,
			$config_win->{'apply_button'},
			\&{          sub { shift->Close() }
				}
		);
		EVT_BUTTON(
			$config_win,
			$config_win->{'save_button'},
			\&{          sub { shift->Close() }
				}
		);
		EVT_BUTTON(
			$config_win,
			$config_win->{'restore_button'},
			\&{          sub { shift->Close() }
				}
		);
		EVT_BUTTON(
			$config_win,
			$config_win->{'cancel_button'},
			\&{          sub { shift->Close() }
				}
		);
		EVT_CLOSE( $config_win, \&quit_config_dialog );

		sub quit_config_dialog {
			my ( $win, $event ) = @_;
			if ( $Kephra::config{'dialog'}{'config'}{'save_position'} == 1 ) {
				(               $Kephra::config{'dialog'}{'config'}{'position_x'},
					$Kephra::config{'dialog'}{'config'}{'position_y'}
					)
					= $win->GetPositionXY();
			}
			$Kephra::temp{'config'}{'dialog_active'} = 0;
			$win->Destroy();
		}

		} else {
		$frame->{'config_win'}->Iconize(0);
		$frame->{'config_win'}->Raise();
	}

}

1;

