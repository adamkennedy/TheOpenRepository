package PCE::App::MainToolBar;
$VERSION = '0.05';

use strict;
use constant CFGROOT => 'main'; 
use constant APPROOT => 'main'; 

sub _get{ PCE::App::ToolBar::_get( (APPROOT) ) }
sub _set{ PCE::App::ToolBar::_set( (APPROOT), $_[0] ) }
sub _get_config{ $PCE::config{'app'}{'toolbar'}{'main'} }

sub create {
	return until get_visibility();
	my $frame = PCE::App::Window::_get();
	my $bar = $frame->GetToolBar;
	$bar->Destroy if $bar;          # destroy old toolbar if there any
	$bar = $frame->CreateToolBar;
	PCE::App::ToolBar::_set('main', $bar);

	my $config = _get_config();
	my $file_name = $PCE::internal{path}{config} . $config->{file};
	my $bars_def = YAML::LoadFile($file_name);# DumpFile
	PCE::App::ToolBar::create('main', $bars_def->{ $config->{node} } );
}


sub get_visibility    { _get_config()->{'visible'} }
sub switch_visibility { _get_config()->{'visible'} ^= 1; show(); }
sub show {
	my $frame = PCE::App::Window::_get();
	if ( get_visibility() )   { create() }
	else {
		_get()->Destroy;
		$frame->SetToolBar(undef);
	}
}

1;
