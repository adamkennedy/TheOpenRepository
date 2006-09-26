package Kephra::App;
our $VERSION = '0.04';

use strict;
use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM
	wxVERTICAL 
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR  
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxBITMAP_TYPE_JPEG wxBITMAP_TYPE_PNG wxBITMAP_TYPE_ICO wxBITMAP_TYPE_XPM
	wxTheClipboard
);

sub _get{ $Kephra::app{'ref'} };
sub _set{ $Kephra::app{'ref'} = shift };

# main layout, main frame
sub splashscreen {
	Wx::InitAllImageHandlers();
	Wx::SplashScreen->new(
		Wx::Bitmap->new(
			$Kephra::temp{path}{config}.$Kephra::temp{file}{img}{splashscreen},
			wxBITMAP_TYPE_JPEG
		),
		wxSPLASH_CENTRE_ON_SCREEN | wxSPLASH_TIMEOUT, 150, undef, -1,
		wxDefaultPosition, wxDefaultSize,
		wxSIMPLE_BORDER | wxFRAME_NO_TASKBAR | wxSTAY_ON_TOP
	);
}

sub assemble_layout {
	my $win = Kephra::App::Window::_get();

	my $main_sizer = $win->{'sizer'} = Wx::BoxSizer->new(wxVERTICAL);
	$main_sizer->Add( Kephra::App::TabBar::_get_sizer(), 0, wxTOP|wxGROW, 0 );
	#$main_sizer->AddSpace(8, 0) if ($^O eq 'linux'); #dirty lin hack remove asap
	$main_sizer->Add( Kephra::App::EditPanel::_get(),    1, wxTOP|wxGROW, 0 );
	if (Kephra::App::SearchBar::_get_config()->{'position'} eq 'top') {
		$main_sizer->Prepend(Kephra::App::SearchBar::_get(), 0, wxTOP|wxGROW, 2)
	} else {
		$main_sizer->Add(Kephra::App::SearchBar::_get(), 0, wxBOTTOM|wxGROW, 3)
	}
	$win->SetSizer($main_sizer);
	$win->SetAutoLayout(1);
	$win->Layout;
	$win->SetBackgroundColour(Kephra::App::TabBar::_get_tabs()->GetBackgroundColour);
	Kephra::App::TabBar::show();
	$win;
}

sub start {
	use Benchmark qw(:all);
	my $t0 = new Benchmark;
	my $app = shift;
	_set($app);
	splashscreen();             # 2'nd splashscreen can close when app is ready
	Wx::InitAllImageHandlers();
	my $frame = Kephra::App::Window::create();
	my $ep = Kephra::App::EditPanel::create();
	$Kephra::temp{'document'}{'open'}[0]{'pointer'} = $ep->GetDocPointer();
	$Kephra::temp{'document'}{'buffer'} = 1;
	Kephra::Config::Global::load_autosaved();
	if (Kephra::Config::Global::evaluate()) {
		$frame->Show(1);
		print "pce startet in:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n";
		my $t2 = new Benchmark;
		Kephra::File::Session::restore();
		Kephra::Document::Internal::add($_) for @ARGV;
		print "pce dateien in:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t2 ) ), "\n";
		1;                      # everything is good
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	my $t0 = new Benchmark;
	return if Kephra::Dialog::save_on_exit() eq 'cancel';
	Kephra::Config::Global::refresh();
	Kephra::File::Session::store();
	Kephra::File::Session::delete();
	Kephra::Config::Global::save_autosaved();
	if ($Kephra::config{app}{interface_cache}{use}){
		Kephra::App::CommandList::save_cache() ;
	}
	Kephra::Config::set_xp_style(); #
	wxTheClipboard->Flush;       # set copied text free to the global Clipboard
	Kephra::App::Window::destroy(); # close window
	print "pce shut down in:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n";
}

sub raw_exit { Wx::Window::Destroy(shift) }


#sub new_instance { system("pce.exe") }

1;
