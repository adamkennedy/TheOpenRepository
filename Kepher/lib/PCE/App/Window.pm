package PCE::App::Window;    # Main application window
$VERSION = '0.05';

use strict;
use base qw(Wx::Frame);      #use Wx; use base qw(Wx::Panel);
use Wx qw(
	wxDefaultPosition wxDefaultSize
	wxDEFAULT_FRAME_STYLE wxNO_FULL_REPAINT_ON_RESIZE wxSTAY_ON_TOP 
	wxBITMAP_TYPE_ICO 
);
use constant APPROOT => 'window';

sub _get {$PCE::app{(APPROOT)} }
sub _set {$PCE::app{(APPROOT)} = shift}
sub _get_config {$PCE::config{'app'}{'window'}}

sub create {
	#shift->SUPER::new
	my $win = Wx::Frame->new
		(undef, -1, '', wxDefaultPosition, wxDefaultSize, wxDEFAULT_FRAME_STYLE);
	_set($win);
	$win;
}

sub apply_settings{
	my $win = _get();
	$win->DragAcceptFiles(1);
	my $icon = $PCE::internal{path}{config}._get_config()->{'icon'};
	load_icon( $win, $icon );
	restore_positions();
	eval_on_top_flag();
}

sub load_icon {
	my $frame     = shift;
	my $icon_file = shift;
	if ( -e $icon_file ) {
		my $icon = Wx::Icon->new;
		$icon->LoadFile( $icon_file, wxBITMAP_TYPE_ICO );
		$frame->SetIcon($icon);
	}
}


sub set_title {
	my ( $text, $title ) = shift;
	my $nv_text = "- $PCE::NAME $PCE::VERSION";
	if ($text) { $title = " $text $nv_text" } 
	else { $title = " < $PCE::localisation{app}{tabbar}{untitled} > $nv_text" }
	_get()->SetTitle($title);

}
sub refresh_title {set_title( $PCE::document{'current'}{'path'} )}


sub get_on_top_mode { _get_config()->{'stay_on_top'} }
sub switch_on_top_mode {
	_get_config()->{'stay_on_top'} ^= 1;
	eval_on_top_flag();
}
sub eval_on_top_flag {
	my $win   = _get();
	my $style = $win->GetWindowStyleFlag();
	if ( get_on_top_mode() ) { $style |= wxSTAY_ON_TOP }
	else                     { $style &= ~wxSTAY_ON_TOP }
	$win->SetWindowStyle($style);
	PCE::App::EventList::trigger('app.window.ontop');
}


sub save_positions{
	my $app_win = PCE::App::Window::_get();
	my $config  = _get_config();
	if ($config->{'save_position'}){
		($config->{'position_x'},$config->{'position_y'})=$app_win->GetPositionXY;
		($config->{'size_x'},    $config->{'size_y'})    =$app_win->GetSizeWH;
	}
}
sub restore_positions{
	# main window: resize when its got lost
	my $config  = _get_config();
	my $default  = $config->{'default'};
	my $screen = Wx::GetDisplaySize();
	my ($screen_x, $screen_y ) = ( $screen->GetWidth, $screen->GetHeight );
	if ($config->{'save_position'}){
		if (   ( 0 > $config->{'position_x'} + $config->{'size_x'} )
			or ( 0 > $config->{'position_y'} + $config->{'size_y'} ) ) {
			$config->{'position_x'} = 0;
			$config->{'position_y'} = 0;
			if ( int $default->{'size_x'} == 0 )
				{ $config->{'size_x'} = $screen_x }
			else{ $config->{'size_x'} = $default->{'size_x'} }
			if ( int $default->{'size_y'} == 0 )
				{ $config->{'size_y'} = $screen_y - 55}
			else{ $config->{'size_y'} = $default->{'size_y'} }
		}
		$config->{'position_x'} = 0 if $screen_x < $config->{'position_x'};
		$config->{'position_y'} = 0 if $screen_y < $config->{'position_y'};
	} else {
		$config->{'position_x'} = $default->{'position_x'};
		$config->{'position_y'} = $default->{'position_y'};
		$config->{'size_x'} = $default->{'size_x'};
		$config->{'size_y'} = $default->{'size_y'};
	}
	_get()->SetSize(
		$config->{'position_x'}, $config->{'position_y'},
		$config->{'size_x'},     $config->{'size_y'}
	);
}

sub OnPaint {
	my ( $self, $event ) = @_;
	my $dc = Wx::PaintDC->new($self);  # create a device context (DC)
}

sub OnQuit {
	my ( $self, $event ) = @_;
	$self->Close(1);
}

sub destroy { _get()->Destroy() }

1;
