package Kepher::Dialog;
$VERSION = '0.18';

use strict;

use Wx qw(:filedialog );    # :messagebox
use Wx qw (wxDefaultPosition wxDefaultSize
	wxOK wxYES wxYES_NO wxNO wxCANCEL wxID_CANCEL
	wxICON_INFORMATION wxICON_QUESTION wxICON_WARNING
	wxSAVE wxOPEN     wxMULTIPLE wxSTAY_ON_TOP
);

sub msg_box {
	Wx::MessageBox( $_[1], $_[2], wxOK | wxSTAY_ON_TOP, $_[0], -1, -1 );
}

sub info_box {
	Wx::MessageBox( $_[1], $_[2], wxOK | wxICON_INFORMATION | wxSTAY_ON_TOP,
		$_[0], -1, -1 );
}

sub warning_box {
	Wx::MessageBox( $_[1], $_[2], wxOK | wxICON_WARNING | wxSTAY_ON_TOP,
		$_[0], -1, -1 );
}

sub get_confirm_2 {
	Wx::MessageBox( $_[1], $_[2], wxYES_NO | wxICON_QUESTION | wxSTAY_ON_TOP,
		$_[0], -1, -1 );
}

sub get_confirm_3 {
	Wx::MessageBox( $_[1], $_[2], wxYES_NO | wxCANCEL | wxICON_QUESTION,
		$_[0], $_[3], $_[4] );
}

sub get_file_open {
	Wx::FileSelector( $_[1], $_[2], '', '', $_[3], wxOPEN, $_[0], -1, -1 );
}

sub get_files_open {
	my $dialog = Wx::FileDialog->new(
		$_[0], $_[1], $_[2], '', $_[3], wxOPEN | wxMULTIPLE, [-1,-1] );
	if ($dialog->ShowModal != wxID_CANCEL) {
		my @files = $dialog->GetPaths;
		return \@files;
	}
}

sub get_file_save {
	Wx::FileSelector( $_[1], $_[2], '', '', $_[3], wxSAVE, $_[0], -1, -1)
}
sub get_font { Wx::GetFontFromUser  ( $_[0], $_[1] ) }
sub get_text { Wx::GetTextFromUser  ( $_[1], $_[2], "", $_[0], -1, -1, 1 ) }
sub get_number{Wx::GetNumberFromUser( $_[1], '', $_[2],$_[3], 0, 100000, $_[0])}

sub find {
	require Kepher::Dialog::Search;
	&Kepher::Dialog::Search::find;
}

sub replace {
	require Kepher::Dialog::Search;
	&Kepher::Dialog::Search::replace;
}

sub info {
	require Kepher::Dialog::Info;
	&Kepher::Dialog::Info::combined;
}

sub config {
	require Kepher::Dialog::Config;
	&Kepher::Dialog::Config::main;
}

sub save_on_exit {
	require Kepher::Dialog::Exit;
	&Kepher::Dialog::Exit::save_on_exit;
}

1;

