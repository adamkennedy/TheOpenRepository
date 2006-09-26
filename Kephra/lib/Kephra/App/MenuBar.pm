package Kephra::App::MenuBar;
$VERSION = '0.05';

use strict;
use constant APPROOT => 'menubar';
use constant CFGROOT => 'menubar';

sub _get{ $Kephra::app{(APPROOT)} }
sub _set{ $Kephra::app{(APPROOT)} = $_[0] if ref $_[0] eq 'Wx::MenuBar'}

sub create {
	my $config = $Kephra::config{'app'}{(CFGROOT)};
	my $file_name = $Kephra::temp{path}{config} . $config->{file};
	my $menubar_def = YAML::LoadFile($file_name);# DumpFile
	my $menubar = Wx::MenuBar->new();
	for my $menu_def ( @{$menubar_def->{ $config->{node} }} ){
		for my $menu_id (keys %$menu_def){
			$menubar->Append(
				Kephra::App::Menu::create_static( $menu_id, $menu_def->{$menu_id}),
				$Kephra::localisation{'app'}{'menu'}{$menu_id}
			);
		}
	}
	Kephra::App::Window::_get()->SetMenuBar($menubar);
	_set($menubar);
}

1;
