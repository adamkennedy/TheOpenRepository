package Kepher::App::MenuBar;

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub _get {
	$Kepher::app{menubar};
}

sub _set {
	$Kepher::app{menubar} = $_[0] if ref $_[0] eq 'Wx::MenuBar';
}

sub create {
	my $config      = $Kepher::config{'app'}{menubar};
	my $file_name   = Kepher::Config::existing_filepath( $config->{file} );
	my $menubar_def = YAML::LoadFile($file_name);
	my $menubar     = Wx::MenuBar->new();
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
