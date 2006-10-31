package Kephra::App::MainToolBar;
$VERSION = '0.06';

use strict;
use constant APPROOT => 'main'; 

sub _get{ Kephra::App::ToolBar::_get( (APPROOT) ) }
sub _set{ Kephra::App::ToolBar::_set( (APPROOT), $_[0] ) }
sub _get_config{ $Kephra::config{'app'}{'toolbar'}{'main'} }

sub create {
	return until get_visibility();
	my $frame = Kephra::App::Window::_get();
	my $bar = $frame->GetToolBar;
	$bar->Destroy if $bar;          # destroy old toolbar if there any
	_set( $frame->CreateToolBar );

	my $config = _get_config();
	my $file_name = $Kephra::temp{path}{config} . $config->{file};
	my $bar_def = Kephra::Config::File::load($file_name);
	$bar_def = Kephra::Config::Tree::get_subtree( $bar_def, $config->{node});
	Kephra::App::ToolBar::create((APPROOT), $bar_def);
}


sub get_visibility    { _get_config()->{'visible'} }
sub switch_visibility { _get_config()->{'visible'} ^= 1; show(); }
sub show {
	if ( get_visibility() ){
		create()
	} else {
		_get()->Destroy;
		Kephra::App::Window::_get()->SetToolBar(undef);
	}
}

1;
