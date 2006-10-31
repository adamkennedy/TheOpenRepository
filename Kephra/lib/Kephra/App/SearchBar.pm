package Kephra::App::SearchBar;
$VERSION = '0.11';

use strict;
use Wx qw(
	wxITEM_NORMAL wxTOP wxGROW
	wxWANTS_CHARS wxDefaultValidator
	wxTB_HORIZONTAL wxTB_DOCKABLE
	wxBITMAP_TYPE_XPM wxNullBitmap
);
use Wx::Event qw( 
	EVT_TEXT EVT_KEY_DOWN EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_COMBOBOX
);
use constant APPROOT => 'search';

sub _get{ Kephra::App::ToolBar::_get( (APPROOT) ) }
sub _set{ Kephra::App::ToolBar::_set( (APPROOT), $_[0] ) }
sub _get_config { $Kephra::config{'app'}{'toolbar'}{'search'} }


sub create {
	# load searchbar definition
	my $config = _get_config();
	my $file_name = $Kephra::temp{path}{config} . $config->{file};
	my $bar_def = Kephra::Config::File::load($file_name);
	$bar_def = Kephra::Config::Tree::get_subtree( $bar_def, $config->{node});
	# create searchbar with buttons
	my $rest_widgets = Kephra::App::ToolBar::create_new( (APPROOT), $bar_def);
	my $bar = _get();
	# apply special searchbar widgets
	for my $item_data (@$rest_widgets){
		if ($item_data->{type} eq 'combobox' and $item_data->{id} eq 'find'){
			my $find_input = $bar->{find_input} = Wx::ComboBox->new
				($bar , -1, '', [-1,-1],[$item_data->{size},-1],[],,1);
			$find_input->SetDropTarget( SearchInputTarget->new($find_input, 'find'));
			$find_input->SetValue( Kephra::Edit::Search::get_find_item() );
			$find_input->SetSize($item_data->{size},-1) if $item_data->{size};
			if ( $Kephra::config{'search'}{'history'}{'use'} ){
				$find_input->Append($_)
					for @{$Kephra::config{search}{history}{find_item}}
			}
			$bar->InsertControl( $item_data->{pos}, $find_input );

			EVT_TEXT( $bar, $find_input, sub {
				my ($bar, $event) = @_;
				Kephra::Edit::Search::set_find_item( $find_input->GetValue );
				colour_find_input( Kephra::Edit::Search::first_increment() )
					if $Kephra::config{'search'}{'attribute'}{'incremental'}
					and Wx::Window::FindFocus() eq $find_input;
#print (Wx::Window::FindFocus())."\n";
#print "ch\n";
#print "searchbar input changed ".Kephra::Edit::Search::get_find_item()."-".$find_input->GetValue."\n";
			} );
			EVT_KEY_DOWN( $find_input, sub {
#print "key in sb pressed \n";
				my ( $fi, $event ) = @_;
				my $found_something;
				my $key = $event->GetKeyCode;
				if ( $key == 13 ) {
					if    ( $event->ControlDown and $event->ShiftDown)   
												 {Kephra::Edit::Search::find_last() }
					elsif ( $event->ControlDown ){Kephra::Edit::Search::find_first()}
					elsif ( $event->ShiftDown )  {Kephra::Edit::Search::find_prev() }
					else                         {Kephra::Edit::Search::find_next() }
					#refresh_find_input($Kephra::temp{'search'}{'history'}{'refresh'})
						#if $Kephra::config{'search'}{'history'}{'use'};
				} elsif ( $key == 27 ) {
					give_editpanel_focus_back()
				} elsif ( $key == 70 and $event->ControlDown ) {
					give_editpanel_focus_back()
				} elsif ( $key == 344 ){ 
					$event->ShiftDown 
						? Kephra::Edit::Search::find_prev()
						: Kephra::Edit::Search::find_next();
				} #else  { print $key;}
				$event->Skip;
			} );
			EVT_COMBOBOX( $find_input, -1, sub{
				#Kephra::Edit::Search::set_find_item( $find_input->GetValue );
				#colour_find_input( Kephra::Edit::Search::first_increment() )
					#if $Kephra::config{'search'}{'attribute'}{'incremental'};
				#print "comb\n";
			} );
			EVT_ENTER_WINDOW( $find_input, sub{
				Wx::Window::SetFocus($find_input) if _get_config()->{'autofocus'};
				disconnect_find_input();
			});
			EVT_LEAVE_WINDOW( $find_input, sub{ connect_find_input($find_input) });
			connect_find_input($find_input);
		}
	}
	$bar->Realize;
	EVT_LEAVE_WINDOW($bar, \&leave_focus);
	show();
}


sub disconnect_find_input{
	Kephra::App::EventList::del_call('find.item.changed','search_bar');
}
sub connect_find_input{
	my $find_input = shift;
	Kephra::App::EventList::add_call( 'find.item.changed', 'search_bar', sub {
			$find_input->SetValue(&Kephra::Edit::Search::get_find_item);
			$find_input->SetInsertionPointEnd;
	});
}
sub refresh_find_input {
	my $find_input     = _get()->{'find_input'};
	my $new_find_item  = shift;
	my $value  = $find_input->GetValue;

#print $find_input->GetValue."-".$find_input->GetString(0)."-$new_find_item-\n";
	if ($new_find_item and $find_input->GetString(0) ne $value){
			#$find_input->Clear();
			#$find_input->Append($_) for @{ $Kephra::config{'search'}{'history'}{'find_item'} };
			#$find_input->SetValue(Kephra::Edit::Search::get_find_item());
			#$find_input->SetInsertionPointEnd;

	}
	#colour_find_input( $new_find_item );
	#Wx::Window::SetFocus( $find_input );
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

sub enter_focus{
	my $bar = _get();
	switch_visibility() unless get_visibility();
	Wx::Window::SetFocus($bar->{find_input}) if defined $bar->{find_input};
}
sub leave_focus{ switch_visibility() if _get_config()->{'autohide'} }

sub give_editpanel_focus_back{
	leave_focus();
	Wx::Window::SetFocus( Kephra::App::EditPanel::_get() );
}


# set visibility
sub show {
	_get()->Show( get_visibility() );
	my $sizer = Kephra::App::Window::_get()->GetSizer;
	$sizer->Layout() if $sizer;
}

sub get_visibility { _get_config()->{'visible'} }
sub switch_visibility {
	_get_config()->{'visible'} ^= 1;
	show();
}


sub ensure_position{
	my $win   = Kephra::App::Window::_get();
	my $bar   = _get();
	my $sizer = $win->GetSizer;
	#$sizer->Detach($bar);
	if (_get_config()->{'position'} eq 'below') {
		$sizer->Insert(0, $bar, wxTOP|wxGROW);
	} else {
		$sizer->Add($bar, wxTOP|wxGROW);
	}
}

1;
