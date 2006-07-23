package PCE::App::StatusBar;
$VERSION = '0.02';

use strict;
use Wx::Event qw( EVT_LEFT_DOWN EVT_RIGHT_DOWN );
use constant APPROOT => 'status'; 


sub _get { $PCE::app{statusbar} }
sub _get_item {}
sub _get_config { $PCE::config{'app'}{'statusbar'} }

sub create {
	# StatusBar settings, will be removed by stusbar config file
	$PCE::internal{'app'}{'status'}{'cursor'}{'index'}    = 0;
	$PCE::internal{'app'}{'status'}{'selection'}{'index'} = 1;
	$PCE::internal{'app'}{'status'}{'style'}{'index'}     = 2;
	$PCE::internal{'app'}{'status'}{'tab'}{'index'}       = 3;
	$PCE::internal{'app'}{'status'}{'EOL'}{'index'}       = 4;
	$PCE::internal{'app'}{'status'}{'message'}{'index'}   = 5;

	my $win = PCE::App::Window::_get();
	$win->CreateStatusBar(1);
	my $bar = $win->GetStatusBar;

	$bar->SetFieldsCount(6);
	if ( $^O eq 'linux' ) { $bar->SetStatusWidths( 90, 66, 60, 40, 70, -1 ) }
	else                  { $bar->SetStatusWidths( 66, 60, 50, 25, 32, -1 ) }
	$win->SetStatusBarPane($PCE::internal{'app'}{'status'}{'message'}{'index'});

	EVT_LEFT_DOWN ( $bar,  \&left_click);
	EVT_RIGHT_DOWN( $bar,  \&right_click);

	PCE::App::EventList::add_call
		('caret.move',           'caret_status',\&caret_pos_info);
	PCE::App::EventList::add_call
		('document.text.change', 'status_msg',  \&refresh_info_msg);
	PCE::App::EventList::add_call
		('editpanel.focus',      'status_msg',  \&refresh_info_msg);

	show();
}


sub get_visibility { _get_config()->{'visible'} }
sub switch_visibility {
	_get_config()->{'visible'} ^= 1;
	show();
	PCE::App::Window::_get()->Layout();
}
sub show { PCE::App::Window::_get()->GetStatusBar->Show( get_visibility() ) }

sub right_click {
	return unless get_interactive();
	my ( $bar,    $event )  = @_;
	my ( $x,      $y )      = ( $event->GetX, $event->GetY );
	my $menu = \&PCE::App::ContextMenu::get;
	if ( $^O eq 'linux' ) {
		if    ($x < 156) {}
		elsif ($x < 215) {$bar->PopupMenu( &$menu('status_syntaxmode'), $x, $y)}
		elsif ($x < 256) {$bar->PopupMenu( &$menu('status_tab'),        $x, $y)}
		elsif ($x < 326) {$bar->PopupMenu( &$menu('status_eol'),        $x, $y)}
	} else {
		if    ($x < 128) {}
		elsif ($x < 180) {$bar->PopupMenu( &$menu('status_syntaxmode'), $x, $y)}
		elsif ($x < 206) {$bar->PopupMenu( &$menu('status_tab')       , $x, $y)}
		elsif ($x < 241) {$bar->PopupMenu( &$menu('status_eol')       , $x, $y)}
	}
}


sub left_click {
	return unless get_interactive();
	my ( $bar,    $event )  = @_;
	my ( $x,      $y )      = ( $event->GetX, $event->GetY );
	my $menu = \&PCE::App::ContextMenu::get;
	if ( $^O eq 'linux' ) {
		if    ($x < 156) {}
		elsif ($x < 215) {$bar->PopupMenu(&$menu('status_syntaxmode'), $x, $y )}
		elsif ($x < 256) {&PCE::Document::switch_tab_mode;}
		elsif ($x < 326) {$bar->PopupMenu(&$menu('status_eol')       , $x, $y )}
		else             {next_file_info()}
	} else {
		if    ($x < 128) {}
		elsif ($x < 180) {$bar->PopupMenu(&$menu('status_syntaxmode'), $x, $y )}
		elsif ($x < 206) {&PCE::Document::switch_tab_mode}
		elsif ($x < 241) {$bar->PopupMenu(&$menu('status_eol'),        $x, $y )}
		else             {next_file_info()}
	}
}

sub get_interactive { _get_config()->{'interactive'} }
sub get_contexmenu_visibility { &get_interactive }
sub switch_contexmenu_visibility { _get_config()->{'interactive'} ^= 1 }


sub refresh {
	caret_pos_info();
	refresh_file_info();
}

sub caret_pos_info {
	my $frame  = PCE::App::Window::_get();
	my $ep     = PCE::App::STC::_get();
	my $pos    = $ep->GetCurrentPos;
	my $line   = $ep->LineFromPosition($pos) + 1;
	my $lpos   = $ep->GetColumn($pos) + 1;
	my $cindex = $PCE::internal{'app'}{'status'}{'cursor'}{'index'};
	my $sindex = $PCE::internal{'app'}{'status'}{'selection'}{'index'};
	my ($value);

	# caret pos display
	if ( $line > 9999  or $lpos > 9999 ) {
	       $frame->SetStatusText( " $line : $lpos", $cindex ) }
	else { $frame->SetStatusText( "  $line : $lpos", $cindex ) }

	# selection or  pos % display
	my ( $sel_beg, $sel_end ) = $ep->GetSelection;
	if ( $PCE::internal{'current_doc'}{'text_selected'} ) {
		my $chars = $ep->GetLength;
		if ($chars) {
			my $value = int 100 * $pos / $chars + .5;
			$value = ' ' . $value if $value < 10;
			$value = ' ' . $value . ' ' if $value < 100;
			$frame->SetStatusText( "    $value%", $sindex );
		} else { $frame->SetStatusText( "    100%", $sindex ) }
		$PCE::internal{'edit'}{'selected'} = 0;
	} else {
		if ( $ep->SelectionIsRectangle ) {
			my $x = abs int $ep->GetColumn($sel_beg) - $ep->GetColumn($sel_end);
			my $lines = 1 + abs int $ep->LineFromPosition($sel_beg)
				- $ep->LineFromPosition($sel_end);
			my $chars = $x * $lines;
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			$frame->SetStatusText( $value , $sindex );
		} else {
			my $lines = 1 + $ep->LineFromPosition($sel_end)
			              - $ep->LineFromPosition($sel_beg);
			my $chars = $sel_end - $sel_beg - 
				($lines - 1) * $PCE::internal{'current_doc'}{'EOL_length'};
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			$frame->SetStatusText( $value, $sindex );
		}
		$PCE::internal{'edit'}{'selected'} = 1;
	}
	#status_msg();
	#$sci->CallTipShow($pos-1, $match_before);
	#$sci->AutoCompShow(2,'ara arab aha')
}

sub style_info {
	my $style = shift;
	if ( !$style ) {
		my $doc_nr = &PCE::Document::_get_current_nr;
		$style = $PCE::document{'current'}{'syntaxstyle'};
	}
	PCE::App::Window::_get()->SetStatusText( " " . $style,
		$PCE::internal{'app'}{'status'}{'style'}{'index'} );
}

sub tab_info {
	my $win   = PCE::App::Window::_get();
	my $mode  = PCE::App::STC::_get()->GetUseTabs;
	my $index = $PCE::internal{'app'}{'status'}{'tab'}{'index'};
	#$mode = 0 unless $mode;
	$mode ? $win->SetStatusText( " HT", $index ) 
		  : $win->SetStatusText( " ST", $index );
}

sub EOL_info {
	my ( $mode, $msg ) = shift;
	$mode = $PCE::internal{'file'}{'current'}{'one'}{'EOL'} if !$mode;
	if    ( $mode eq 'cr'    or $mode eq 'mac' ) { $msg = " Mac" }
	elsif ( $mode eq 'lf'    or $mode eq 'lin' ) { $msg = "Linux" }
	elsif ( $mode eq 'cr+lf' or $mode eq 'win' ) { $msg = " Win" }
	elsif ( $mode eq 'none'  or $mode eq 'no' )  {
		$msg = $PCE::localisation{'dialog'}{'general'}{'none'};
	}
	PCE::App::Window::_get()->SetStatusText
		( $msg, $PCE::internal{'app'}{'status'}{'EOL'}{'index'} );
}

sub info_msg {
	return unless $_[0];
	PCE::App::Window::_get()->SetStatusText( shift,
		$PCE::internal{'app'}{'status'}{'message'}{'index'}
	);
}

sub refresh_info_msg {file_info() }
sub refresh_file_info { file_info( _get_config()->{'msg_nr'} )  }

sub next_file_info {
	my $info_nr = \_get_config()->{'msg_nr'};

	#$$info_nr = 0 unless $status_bar->GetStatusText($index);
	$$info_nr++;
	$$info_nr = 0 if $$info_nr > 2;
	file_info();
}

sub file_info {
	my $msg = _get_config()->{'msg_nr'}
		? _get_file_info( _get_config()->{'msg_nr'} ) : '';
	PCE::App::Window::_get()->GetStatusBar->SetStatusText
		($msg, $PCE::internal{'app'}{'status'}{'message'}{'index'} );
}

sub _get_file_info {
	my $selector = shift;
	return '' unless $selector;
	my $l10 = $PCE::localisation{app}{status};

	# show how big file is
	if ( $selector == 1 ) {
		my $ep = PCE::App::STC::_get();

		return sprintf ' %s: %s   %s: %s',
			$l10->{chars}, $ep->GetLength, $l10->{lines}, $ep->GetLineCount;

	# show how old file is
	} elsif ( $selector == 2 ) {
		my $file_name = PCE::Document::_get_current_file_path();
		if ($file_name) {
			my @time = localtime( $^T - ( -M $file_name ) * 86300 );
			return sprintf ' %s: %02d:%02d - %02d.%02d.%d', $l10->{last_change},
				$time[2], $time[1], $time[3], $time[4] + 1, $time[5] + 1900;
		} else {
			my @time = localtime;
			return sprintf ' %s: %02d:%02d - %02d.%02d.%d', $l10->{now_is},
				$time[2], $time[1], $time[3], $time[4] + 1, $time[5] + 1900;
		}
	}
}


1;
