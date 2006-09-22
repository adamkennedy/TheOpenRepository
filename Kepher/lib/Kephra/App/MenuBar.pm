package Kepher::App::MenuBar;
$VERSION = '0.05';

use strict;
use constant APPROOT => 'menubar';
use constant CFGROOT => 'menubar';

sub _get{ $Kepher::app{(APPROOT)} }
sub _set{ $Kepher::app{(APPROOT)} = $_[0] if ref $_[0] eq 'Wx::MenuBar'}

sub create {
	my $config = $Kepher::config{'app'}{(CFGROOT)};
	my $file_name = $Kepher::internal{path}{config} . $config->{file};
	my $menubar_def = YAML::LoadFile($file_name);# DumpFile
	my $menubar = Wx::MenuBar->new();
	for my $menu_def ( @{$menubar_def->{ $config->{node} }} ){
		for my $menu_id (keys %$menu_def){
			$menubar->Append(
				Kepher::App::Menu::create_static( $menu_id, $menu_def->{$menu_id}),
				$Kepher::localisation{'app'}{'menu'}{$menu_id}
			);
		}
	}
	Kepher::App::Window::_get()->SetMenuBar($menubar);
	_set($menubar);
}

1;
