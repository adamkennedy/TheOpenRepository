package Kepher::App::SearchBar;
$VERSION = '0.08';

use strict;
use Wx qw(
	wxITEM_NORMAL wxTOP wxGROW
	wxTB_HORIZONTAL wxTB_DOCKABLE
	wxBITMAP_TYPE_XPM wxNullBitmap
	wxWANTS_CHARS wxDefaultValidator
);
use Wx::Event qw( 
	EVT_TOOL EVT_MENU EVT_TEXT EVT_KEY_DOWN EVT_ENTER_WINDOW EVT_LEAVE_WINDOW
);
use constant APPROOT => 'searchbar';

sub _get { $Kepher::app{'window'}{(APPROOT)} }
sub _set { $Kepher::app{'window'}{(APPROOT)} = shift }
sub _get_config { $Kepher::config{'app'}{'toolbar'}{'search'} }

sub _create_empty {
	return $Kepher::app{window}{(APPROOT)} =
		Wx::ToolBar->new( Kepher::App::Window::_get(),
			-1, [-1,-1], [-1,-1], wxTB_HORIZONTAL|wxTB_DOCKABLE );
}

sub create {
	my $ico_dir = $Kepher::internal{path}{config}.$Kepher::config{app}{iconset_path};
	my $label = \%{$Kepher::localisation{commandlist}{label}};
	my $xpm_bt = wxBITMAP_TYPE_XPM;

	#
	my $sb = _get();
	$sb->Destroy if ref $sb eq 'Wx::ToolBar';
	$sb = _create_empty();

	#
	my ($find_input, $item_id);
	if (exists $Kepher::app{(APPROOT)}{item_id}){
		$item_id = $Kepher::app{(APPROOT)}{item_id}
	} else { $item_id = $Kepher::app{GUI}{masterID}++ * 100 }
	# prepare search-keywords-input-combobox
	unless ($sb->{find_input}){
		$sb->{find_input} = Wx::ComboBox->new(
			$sb, -1, Kepher::Edit::Search::get_find_item(),[-1,-1],[160,-1],[],,1);
		$sb->{find_input}->SetDropTarget
			( SearchInputTarget->new($find_input, 'find'));
	}
	$find_input = $sb->{find_input};
	if ( $Kepher::config{'search'}{'history'}{'use'} ){
		$find_input->Append($_) for @{$Kepher::config{search}{history}{find_item}}
	}
	EVT_TEXT( $sb, $find_input,   \&find_increment );
	EVT_KEY_DOWN(  $find_input,   sub {
		my ( $fi, $event ) = @_;
		my $found_something;
		my $key = $event->GetKeyCode;
		if ( $key == 13 ) {
			if  ( $event->ControlDown and $event->ShiftDown)   
			                             {Kepher::Edit::Search::find_last() }
			elsif ( $event->ControlDown ){Kepher::Edit::Search::find_first()}
			elsif ( $event->ShiftDown )  {Kepher::Edit::Search::find_prev() }
			else                         {Kepher::Edit::Search::find_next() }
			refresh_find_input($Kepher::internal{'search'}{'history'}{'refresh'})
				if $Kepher::config{'search'}{'history'}{'use'};
		} elsif ( $key == 27 ) {
			give_editpanel_focus_back()
		} elsif ( $key == 70 and $event->ControlDown ) {
			give_editpanel_focus_back()
		} else  { $event->Skip }
		1;
	} );
	EVT_ENTER_WINDOW( $find_input, sub { refresh_find_input(1)} )
		if _get_config()->{'autofocus'};

	# build toolbar #$sb->SetSize(-1,30); #$sb->SetMargins( 14, 14 );
	$sb->AddTool( 50100,'',Wx::Bitmap->new($ico_dir.'edit_delete.xpm', $xpm_bt),
		$Kepher::localisation{dialog}{general}{close}, wxITEM_NORMAL);
	EVT_MENU( $sb, 50100, \&switch_visibility );
	$sb->AddControl( $find_input );
	#$sb->AddTool( 50101,'', Wx::Bitmap->new($ico_dir.'find_start.xpm', wxBITMAP_TYPE_XPM),
		#$label->{mark_all}, wxITEM_NORMAL);
	#EVT_MENU( $sb, 50101, sub { refresh_find_input(Kepher::Edit::Search::find_prev()) } );
	$sb->AddTool( 50102,'',Wx::Bitmap->new($ico_dir.'find_previous.xpm', $xpm_bt),
		$label->{find}{prev},wxITEM_NORMAL);
	EVT_MENU( $sb, 50102, sub { refresh_find_input(Kepher::Edit::Search::find_prev()) } );
	$sb->AddTool( 50103,'',Wx::Bitmap->new($ico_dir.'find_next.xpm', $xpm_bt),
		$label->{find}{'next'},wxITEM_NORMAL);
	EVT_MENU( $sb, 50103, sub { refresh_find_input(Kepher::Edit::Search::find_next()) } );
	$sb->AddSeparator();
	$sb->AddTool( 50104,'',Wx::Bitmap->new($ico_dir.'goto_last_edit.xpm', $xpm_bt),
		$label->{'goto'}{'last-edit'}, wxITEM_NORMAL);
	EVT_MENU( $sb, 50104, \&Kepher::Edit::Goto::last_edit );
	$sb->AddSeparator();
	$sb->AddTool( 50105,'',Wx::Bitmap->new($ico_dir.'find_start.xpm', $xpm_bt),
		$label->{view}{dialog}{find}, wxITEM_NORMAL);
	EVT_MENU( $sb, 50105, \&Kepher::Dialog::find );
	$sb->SetRows(1);

	EVT_LEAVE_WINDOW($sb, \&leave_focus);
	$sb->Realize();
	show();
}


sub find_increment{
	my ($bar, $event) = @_;
	my $find_input    = _get()->{'find_input'};
	Kepher::Edit::Search::set_find_item( $find_input->GetValue );
	colour_find_input( Kepher::Edit::Search::first_increment() )
		if $Kepher::config{'search'}{'attribute'}{'incremental'};
}


sub refresh_find_input {
	my $find_input     = _get()->{'find_input'};
	my $new_find_item  = shift;
	my $value  = $find_input->GetValue;

#print $find_input->GetValue."-".$find_input->GetString(0)."-$new_find_item-\n";
	if ($new_find_item and $find_input->GetString(0) ne $value){
			$find_input->Clear();
			$find_input->Append($_) for @{ $Kepher::config{'search'}{'history'}{'find_item'} };
			$find_input->SetValue(Kepher::Edit::Search::get_find_item());
			#$find_input->SetInsertionPointEnd;

	}
	colour_find_input( $new_find_item );
	Wx::Window::SetFocus( $find_input );
}

sub colour_find_input{
	my $find_input      = _get()->{'find_input'};
	my $found_something = shift;
	if ($found_something){
		$find_input->SetForegroundColour( Wx::Colour->new( 0x00, 0x00, 0x33 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	} else {
		$find_input->SetForegroundColour( Wx::Colour->new( 0xff, 0x33, 0x33 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	}
	$find_input->Refresh;
}

sub activate{
    my $text = Kepher::App::STC::_get()->GetSelectedText();
    Kepher::Edit::Search::set_find_item($text) if $text;
    enter_focus();
}

# focus handling
sub enter_focus{
	my $sb = _get();
	my $find_input = $sb->{'find_input'};
	if (Wx::Window::FindFocus() eq $find_input){
		give_editpanel_focus_back();
		return;
	}
	$find_input->SetValue( Kepher::Edit::Search::get_find_item() );
	switch_visibility() unless $sb->IsShown();
	#Wx::Window::SetFocus( $sb );
	Wx::Window::SetFocus( $find_input );
	$Kepher::internal{'search'}{'old_pos'} = Kepher::App::STC::_get()->GetCurrentPos();
}


sub leave_focus{
	switch_visibility() if _get_config()->{'autohide'};
}


sub give_editpanel_focus_back{
	Wx::Window::SetFocus( Kepher::App::STC::_get() );
	leave_focus();
}


# set visibility
sub show {
	_get()->Show( get_visibility() );
	my $sizer = Kepher::App::Window::_get()->GetSizer;
	$sizer->Layout() if $sizer;
}

sub get_visibility { _get_config()->{'visible'} }
sub switch_visibility {
	_get_config()->{'visible'} ^= 1;
	show();
}


sub ensure_position{
	my $app_win    = Kepher::App::Window::_get();
	my $sb         = _get();
	my $main_sizer = $app_win->GetSizer;
	#$main_sizer->Detach($sb);
	if (_get_config()->{'position'} eq 'below') {
		$main_sizer->Insert(0, $sb, wxTOP|wxGROW);
	} else {
		$main_sizer->Add($sb, wxTOP|wxGROW);
	}
}

1;
