package Kepher::App;
our $VERSION = '0.04';

use strict;
use File::Spec ();
use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM
	wxVERTICAL 
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR  
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxBITMAP_TYPE_JPEG wxBITMAP_TYPE_PNG wxBITMAP_TYPE_ICO wxBITMAP_TYPE_XPM
	wxTheClipboard
);

sub get_ref{ $Kepher::app{'ref'} };
sub set_ref{ $Kepher::app{'ref'} = shift };

# main layout, main frame
sub splashscreen {
	Wx::InitAllImageHandlers();
	Wx::SplashScreen->new(
		Wx::Bitmap->new(
			File::Spec->catfile(
				$Kepher::internal{path}{config},
				$Kepher::internal{file}{img}{splashscreen},
				),
			wxBITMAP_TYPE_JPEG
		),
		wxSPLASH_CENTRE_ON_SCREEN | wxSPLASH_TIMEOUT, 150, undef, -1,
		wxDefaultPosition, wxDefaultSize,
		wxSIMPLE_BORDER | wxFRAME_NO_TASKBAR | wxSTAY_ON_TOP
	);
}

sub assemble_layout {
	my $win = Kepher::App::Window::_get();

	my $main_sizer = $win->{'sizer'} = Wx::BoxSizer->new(wxVERTICAL);
	$main_sizer->Add( Kepher::App::TabBar::_get_sizer(), 0, wxTOP|wxGROW, 0 );
	#$main_sizer->AddSpace(8, 0) if ($^O eq 'linux'); #dirty lin hack remove asap
	$main_sizer->Add( Kepher::App::EditPanel::_get(),    1, wxTOP|wxGROW, 0 );
	if (Kepher::App::SearchBar::_get_config()->{'position'} eq 'top') {
		$main_sizer->Prepend(Kepher::App::SearchBar::_get(), 0, wxTOP|wxGROW, 2)
	} else {
		$main_sizer->Add(Kepher::App::SearchBar::_get(), 0, wxBOTTOM|wxGROW, 3)
	}
	$win->SetSizer($main_sizer);
	$win->SetAutoLayout(1);
	$win->Layout;
	$win->SetBackgroundColour(Kepher::App::TabBar::_get_tabs()->GetBackgroundColour);
	Kepher::App::TabBar::show();
	$win;
}

sub start {
	my $app = shift;
	set_ref($app);
	splashscreen();             # 2'nd splashscreen can close when app is ready
	Wx::InitAllImageHandlers();
	my $frame = Kepher::App::Window::create();
	my $ep = Kepher::App::EditPanel::create();
	$Kepher::internal{'document'}{'open'}[0]{'pointer'} = $ep->GetDocPointer();
	$Kepher::internal{'document'}{'buffer'} = 1;
	Kepher::Config::Global::load_autosaved();
	if (Kepher::Config::Global::evaluate()) {
		$frame->Show(1);
		Kepher::File::Session::restore();
		Kepher::Document::Internal::add($_) for @ARGV;
		1;
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	return if Kepher::Dialog::save_on_exit() eq 'cancel';
	Kepher::Config::Global::refresh();
	Kepher::File::Session::store();
	Kepher::File::Session::delete();
	Kepher::Config::Global::save_autosaved();
	if ($Kepher::config{app}{interface_cache}{use}){
		Kepher::App::CommandList::save_cache() ;
	}
	Kepher::Config::set_xp_style(); #
	wxTheClipboard->Flush;       # set copied text free to the global Clipboard
	Kepher::App::Window::destroy(); # close window
}

sub raw_exit { Wx::Window::Destroy(shift) }


#sub new_instance { system("pce.exe") }

1;
