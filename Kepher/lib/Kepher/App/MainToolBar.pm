package KEPHER::App::MainToolBar;
$VERSION = '0.05';

use strict;
use constant CFGROOT => 'main'; 
use constant APPROOT => 'main'; 

sub _get{ KEPHER::App::ToolBar::_get( (APPROOT) ) }
sub _set{ KEPHER::App::ToolBar::_set( (APPROOT), $_[0] ) }
sub _get_config{ $KEPHER::config{'app'}{'toolbar'}{'main'} }

sub create {
	return until get_visibility();
	my $frame = KEPHER::App::Window::_get();
	my $bar = $frame->GetToolBar;
	$bar->Destroy if $bar;          # destroy old toolbar if there any
	$bar = $frame->CreateToolBar;
	KEPHER::App::ToolBar::_set('main', $bar);

	my $config = _get_config();
	my $file_name = $KEPHER::internal{path}{config} . $config->{file};
	my $bars_def = YAML::LoadFile($file_name);# DumpFile
	KEPHER::App::ToolBar::create('main', $bars_def->{ $config->{node} } );
}


sub get_visibility    { _get_config()->{'visible'} }
sub switch_visibility { _get_config()->{'visible'} ^= 1; show(); }
sub show {
	my $frame = KEPHER::App::Window::_get();
	if ( get_visibility() )   { create() }
	else {
		_get()->Destroy;
		$frame->SetToolBar(undef);
	}
}

1;
