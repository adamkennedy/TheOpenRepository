package KEPHER::App::TabBar;    # notebook file selector
$VERSION = '0.10';

use strict;
use constant APPROOT => 'tabbar';
use Wx qw(
        wxTOP wxLEFT wxRIGHT wxHORIZONTAL wxVERTICAL wxALIGN_CENTER_VERTICAL
        wxGROW wxLI_HORIZONTAL wxTAB_TRAVERSAL
        wxBU_AUTODRAW wxNO_BORDER wxBITMAP_TYPE_XPM wxWHITE
);
use Wx::Event qw(
	EVT_LEFT_UP EVT_LEFT_DOWN EVT_MIDDLE_UP EVT_BUTTON
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW
	EVT_NOTEBOOK_PAGE_CHANGED
);

sub _get      { $KEPHER::app{window}{(APPROOT)} }
sub _get_tabs { $KEPHER::app{window}{(APPROOT)}{tabs} }
sub _set_tabs { $KEPHER::app{window}{(APPROOT)}{tabs} = shift }
sub _get_sizer{ $KEPHER::app{window}{(APPROOT)}{sizer} }
sub _set_sizer{ $KEPHER::app{window}{(APPROOT)}{sizer} = shift }
sub _get_config{$KEPHER::config{app}{tabbar} }
#sub new{ return KEPHER::App::Window::_get()->{'notebook'} = Wx::Notebook->new($frame, -1, [0,0], [1,1],)}

sub create {
	my $win = KEPHER::App::Window::_get();

	# create notebook if there is none
	unless (ref _get_tabs() eq 'Wx::Notebook'){
		_set_tabs( Wx::Notebook->new($win, -1, [0,0], [-1,0]) );
		add_page();
	}
	my $tabbar = _get();
	my $tabbar_h_sizer = $tabbar->{h_sizer} = Wx::BoxSizer->new(wxHORIZONTAL);
	my $colour = $tabbar->{tabs}->GetBackgroundColour();
	$tabbar_h_sizer->Add( $tabbar->{tabs} , 1, wxLEFT | wxGROW , 0 );

	# create icons above panels
	my $cmd_new_data = KEPHER::App::CommandList::get_cmd_properties('file-new');
	if (ref $cmd_new_data->{'icon'} eq 'Wx::Bitmap'){
		my $new_btn = $tabbar->{button}{new} = Wx::BitmapButton->new
			($win, -1, $cmd_new_data->{'icon'}, [-1,-1], [-1,-1], wxNO_BORDER );
		$new_btn->SetToolTip( $cmd_new_data->{'label'} );
		$new_btn->SetBackgroundColour( $colour );
		$tabbar_h_sizer->Prepend($new_btn, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2);
		EVT_BUTTON($win, $new_btn, $cmd_new_data->{'call'} );
		EVT_ENTER_WINDOW( $new_btn, sub {
			KEPHER::App::StatusBar::info_msg( $cmd_new_data->{'help'} )
		});
		EVT_LEAVE_WINDOW( $new_btn, \&KEPHER::App::StatusBar::refresh_info_msg );
	}

	my $cmd_close_data = KEPHER::App::CommandList::get_cmd_properties('file-close');
	if (ref $cmd_close_data->{'icon'} eq 'Wx::Bitmap'){
		my $close_btn = $tabbar->{button}{close} = Wx::BitmapButton->new
			($win, -1, $cmd_close_data->{'icon'}, [-1,-1], [-1,-1], wxNO_BORDER );
		$close_btn->SetToolTip( $cmd_close_data->{'label'} );
		$close_btn->SetBackgroundColour( $colour );
		$tabbar_h_sizer->Add($close_btn, 0, wxRIGHT|wxALIGN_CENTER_VERTICAL, 2);
		EVT_BUTTON($win, $close_btn, $cmd_close_data->{'call'} );
		EVT_ENTER_WINDOW($close_btn, sub {
			KEPHER::App::StatusBar::info_msg( $cmd_close_data->{'help'} )
		});
		EVT_LEAVE_WINDOW( $close_btn, \&KEPHER::App::StatusBar::refresh_info_msg );
	}

	#
	$tabbar->{seperator_line} = Wx::StaticLine->new
		($win, -1, [-1,-1],[-1,2], wxLI_HORIZONTAL);
	$tabbar->{seperator_line}->SetBackgroundColour(wxWHITE);

	# assemble tabbar seperator line
	my $tabbar_v_sizer = $tabbar->{v_sizer} = Wx::BoxSizer->new(wxVERTICAL);
	$tabbar_v_sizer->Add( $tabbar->{seperator_line}, 0, wxTOP | wxGROW , 0 );
	$tabbar_v_sizer->Add( $tabbar_h_sizer          , 1, wxTOP | wxGROW , 0 );

	EVT_LEFT_UP(   $tabbar->{tabs}, \&left_off_tabs);
	EVT_LEFT_DOWN( $tabbar->{tabs}, \&left_on_tabs);
	EVT_MIDDLE_UP( $tabbar->{tabs}, KEPHER::App::CommandList::get_cmd_property
			(_get_config()->{'middle_click'}, 'call') );
	EVT_NOTEBOOK_PAGE_CHANGED($win,$tabbar->{tabs}, \&change_tab);

	_set_sizer($tabbar_v_sizer);
	refresh_layout();
}


#
sub add_page {
	my $tabs = _get_tabs();
	$tabs->AddPage( Wx::Panel->new( $tabs, -1, [ -1, -1 ], [ -1, 0 ] ), '', 0 );
}
sub delete_page { _get_tabs()->DeletePage(shift) }
sub set_current_page { 
	my $nr = shift;
	my $tabbar = _get_tabs();
	$tabbar->SetSelection($nr) unless $nr == $tabbar->GetSelection;
}

# refresh the label of given number
sub refresh_label {
	my $config = _get_config();
	my $doc_nr = shift;
	$doc_nr ||= 0;
	return unless defined $KEPHER::internal{'document'}{'open'}[$doc_nr];

	my $doc_internals = \%{ $KEPHER::internal{'document'}{'open'}[$doc_nr] };
	my $label         = $doc_internals->{'name'};
	$label = "<$KEPHER::localisation{app}{tabbar}{untitled}>" unless $label;

	my $max_tab_width = $config->{'tab_width'};
	if ( ( $max_tab_width > 7 ) and ( length($label) > $max_tab_width ) ) {
		$label = substr( $label, 0, $max_tab_width - 3 ) . '...';
	}
	$label = ( $doc_nr + 1 ) . " $label";
	$doc_internals->{'label'} = $label;
	if ( $config->{'info_symbol'} ) {
		$label .= ' #' if $doc_internals->{'readonly'};
		$label .= ' *' if $doc_internals->{'modified'};
	}
	_get_tabs()->SetPageText( $doc_nr, $label );
}

sub refresh_current_label { refresh_label( KEPHER::Document::_get_current_nr() ) }

sub refresh_all_label {
	if ($KEPHER::internal{'document'}{'loaded'}){
		refresh_label($_) for 0 .. KEPHER::Document::_get_last_nr();
		set_current_page( KEPHER::Document::_get_current_nr() );
	}
}

# set tabbar visibility
sub get_visibility { _get_config()->{'visible'} }
sub switch_visibility {
	_get_config()->{'visible'} ^= 1;
	show();
}
sub show {
	my $main_sizer = KEPHER::App::Window::_get()->GetSizer;

	$main_sizer->Show( _get()->{v_sizer}, get_visibility() );
	refresh_layout();
	$main_sizer->Layout();
}

# visibility of parts
sub refresh_layout{
 my $tabbar = _get();
 my $tab_config = _get_config();
	$tabbar->{seperator_line}->Show( $tab_config->{seperator_line} );
	$tabbar->{button}{new}   ->Show( $tab_config->{button}{new}    );
	$tabbar->{button}{close} ->Show( $tab_config->{button}{close}  );
}

sub left_on_tabs {
	my ($tabs, $event) = @_;
	$KEPHER::internal{'document'}{'b4tabchange'} = $tabs->GetSelection;
	$event->Skip;
}
sub left_off_tabs {
	my ($tabs, $event) = @_;
	KEPHER::Document::Change::switch_back()
		if $KEPHER::internal{'document'}{'b4tabchange'} == $tabs->GetSelection;
	$event->Skip;
}
sub change_tab {
	my ( $frame, $event ) = @_;
	KEPHER::Document::Change::to_number($event->GetSelection);
	$event->Skip;
}

1;
