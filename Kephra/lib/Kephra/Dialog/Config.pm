package Kephra::Dialog::Config;
$VERSION = '0.17';

use strict;
use Wx qw( 
	wxVERTICAL wxHORIZONTAL wxLEFT wxTOP wxBOTTOM wxGROW wxEXPAND wxALIGN_CENTRE
	wxSYSTEM_MENU wxCAPTION wxSTAY_ON_TOP wxNO_FULL_REPAINT_ON_RESIZE
	wxSIMPLE_BORDER wxRAISED_BORDER wxNO_BORDER wxRESIZE_BORDER
	wxCLOSE_BOX wxMINIMIZE_BOX  wxFRAME_NO_TASKBAR  wxBITMAP_TYPE_XPM  wxWHITE);

use Wx::Event
	qw(EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE);

sub _get { $Kephra::app{'dialog'}{'config'} }
sub _set { $Kephra::app{'dialog'}{'config'} = $_[0] if ref $_[0] eq 'Wx::Frame' }

sub main {
	if ( !$Kephra::temp{'dialog'}{'config'}{'active'}
	or    $Kephra::temp{'dialog'}{'config'}{'active'} == 0 ) {

		# init search and replace dialog
		$Kephra::temp{'dialog'}{'config'}{'active'} = 1;
		my $frame = Kephra::App::Window::_get();
		my $config = $Kephra::config{'dialog'}{'config'};
		my $d_l10n = $Kephra::localisation{'dialog'}{'settings'};
		my $g_l10n = $Kephra::localisation{'dialog'}{'general'};
		my $ico_dir = $Kephra::temp{path}{config} . 'icon/set/jenne/';
		my $d_style = wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
			| wxMINIMIZE_BOX | wxCLOSE_BOX;
		$d_style |= wxSTAY_ON_TOP if $Kephra::config{'app'}{'window'}{'stay_on_top'};

		# making window & main design
		my $dialog = Wx::Frame->new( $frame, -1, ' '.$d_l10n->{'title'},
			[ $config->{'position_x'}, $config->{'position_y'} ], [ 440, 460 ],
			$d_style);
		Kephra::App::Window::load_icon( $dialog,
			$Kephra::temp{path}{config}.$Kephra::config{'app'}{'window'}{'icon'});
		_set($dialog);

		my $config_main = Wx::Panel->new( $dialog, -1, [0, 0], [480, 460] );
		my $config_menu = Wx::Panel->new( $config_main, -1, [10, 10], [69, 362]);
		$config_menu->SetBackgroundColour(wxWHITE);
		my $menu_border = Wx::StaticBox->new( $config_main, -1, '', 
			[10, 4], [71, 370], wxSIMPLE_BORDER | wxRAISED_BORDER );

		# construction left main menu
		my $program_panel_button = Wx::BitmapButton->new(
			$config_menu, -1, Wx::Bitmap->new
			($ico_dir . 'config_mode_full.xpm', wxBITMAP_TYPE_XPM ),
			[ 11, 6 ], [ 48, 48 ]);
		my $win_panel_button = Wx::BitmapButton->new(
			$config_menu, -1, Wx::Bitmap->new
				( $ico_dir . 'config_mode_full.xpm', wxBITMAP_TYPE_XPM ),
			[ 11, 78 ], [ 48, 48 ]);
		my $edit_panel_button = Wx::BitmapButton->new(
			$config_menu, -1, Wx::Bitmap->new
				( $ico_dir . 'config_mode_full.xpm', wxBITMAP_TYPE_XPM ),
			[ 11, 150 ], [ 48, 48 ]);
		my $files_panel_button = Wx::BitmapButton->new(
			$config_menu, -1, Wx::Bitmap->new
				( $ico_dir . 'config_mode_full.xpm', wxBITMAP_TYPE_XPM ),
			[ 11, 222 ], [ 48, 48 ]);
		my $program_label = Wx::StaticText->new(
			$config_menu, -1, $d_l10n->{'panel'}{'general'},
			[ 0,  56 ], [ 70, 14 ], wxALIGN_CENTRE);
		my $win_label = Wx::StaticText->new(
			$config_menu, -1, $d_l10n->{'panel'}{'main_window'},
			[ 0,  128 ], [ 70, 14 ], wxALIGN_CENTRE );
		my $edit_label = Wx::StaticText->new(
			$config_menu, -1, $d_l10n->{'panel'}{'edit'},
			[ 0,  200 ], [ 70, 14 ], wxALIGN_CENTRE);
		my $file_label = Wx::StaticText->new(
			$config_menu, -1, $d_l10n->{'panel'}{'files'},
			[ 0,  272 ], [ 70, 14 ], wxALIGN_CENTRE);

		#
		$dialog->{'apply_button'} = Wx::Button->new(
			$config_main, -1, $g_l10n->{'apply'},
			[ 83, 392 ], [ 80, -1 ]);
		$dialog->{'save_button'} = Wx::Button->new(
			$config_main, -1, $g_l10n->{'save'},
			[ 172, 392 ], [ 76,  -1 ]);
		$dialog->{'restore_button'} = Wx::Button->new(
			$config_main, -1, $g_l10n->{'restore'},
			[ 257, 392 ], [ 80,  -1 ]);
		$dialog->{'cancel_button'} = Wx::Button->new(
			$config_main, -1, $g_l10n->{'cancel'},
			[ 346, 392 ], [ 76,  -1 ]);

		# release
		$dialog->Show(1);
		Wx::Window::SetFocus( $dialog->{'cancel_button'} );

		# events
		EVT_BUTTON( $dialog, $dialog->{'apply_button'}, sub {shift->Close} );
		EVT_BUTTON( $dialog, $dialog->{'save_button'},  sub {shift->Close} );
		EVT_BUTTON( $dialog, $dialog->{'restore_button'}, sub {shift->Close});
		EVT_BUTTON( $dialog, $dialog->{'cancel_button'},  sub {shift->Close});
		EVT_CLOSE( $dialog, \&quit_config_dialog );

	} else {
			my $dialog = _get();
			$dialog->Iconize(0);
			$dialog->Raise;
	}
}

sub quit_config_dialog {
	my ( $win, $event ) = @_;
	my $config = $Kephra::config{'dialog'}{'config'};
	if ( $config->{'save_position'} == 1 ) {
		($config->{'position_x'}, $config->{'position_y'})
			= $win->GetPositionXY;
	}
	$Kephra::temp{'dialog'}{'config'}{'active'} = 0;
	$win->Destroy;
}

1;