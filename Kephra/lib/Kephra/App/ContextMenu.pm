package Kepher::App::ContextMenu;
$VERSION = '0.07';

use strict;
use constant CFGROOT => 'contextmenu';# name of root node in configs
use Wx::Event qw(EVT_RIGHT_DOWN);
 
sub get{ &Kepher::App::Menu::ready }
#
sub create_all {
	my $config = $Kepher::config{app}{(CFGROOT)};
	my $file_name = $Kepher::internal{path}{config} . $config->{defaultfile};
	my ($tempname, $start_node) = 'contextmenus';
	my $menu_def = YAML::LoadFile($file_name);# DumpFile
	for my $menu_id (keys %{$config->{id}}){
		if (not ref $menu_id){
			$start_node = $config->{id}{$menu_id};
			substr($start_node, 0, 1) eq '&'
				? Kepher::App::Menu::create_dynamic($menu_id, $start_node)
				: Kepher::App::Menu::create_static
					($menu_id, $menu_def->{$start_node});
		}
	}
}


# connect the static and build the dynamic
sub connect_all{
	my $config = $Kepher::config{app};
	connect_editpanel();
	connect_widget
		(&Kepher::App::SearchBar::_get, Kepher::App::SearchBar::_get_config()->{(CFGROOT)});
	connect_widget
		(&Kepher::App::TabBar::_get_tabs, Kepher::App::TabBar::_get_config()->{(CFGROOT)});
}


sub connect_widget{
	my $widget = shift;
	my $menu_id = shift;
	print EVT_RIGHT_DOWN ($widget, sub {
		my ($widget, $event) = @_;
		my $menu = get($menu_id);
		$widget->PopupMenu($menu, $event->GetX, $event->GetY) if $menu;
	} );
}


sub disconnect_widget{
	my $widget = shift;
	EVT_RIGHT_DOWN($widget, sub {} ) if substr(ref $widget, 0, 4) eq 'Wx::';
}


sub connect_editpanel {
	my $edit_panel = Kepher::App::EditPanel::_get();
	my $config = $Kepher::config{'editpanel'}{(CFGROOT)};
	$config->{'visible'} eq 'default' ? $edit_panel->UsePopUp(1)
	                                  : $edit_panel->UsePopUp(0);

	if ($config->{'visible'} eq 'custom'){
		my $id_normal = $config->{ID_normal};   
		my $id_select = $config->{ID_selection};
		EVT_RIGHT_DOWN($edit_panel, sub {
			my ($ep, $event) = @_;
			my $menu_id = $Kepher::internal{'current_doc'}{'text_selected'}
				? $id_select : $id_normal;
			my $menu = get($menu_id);
			$ep->PopupMenu($menu, $event->GetX, $event->GetY) if $menu;
		} );
	} else { disconnect_widget($edit_panel) }
}

sub get_editpanel { $Kepher::config{'editpanel'}{(CFGROOT)}{'visible'} }
sub set_editpanel_custom  { set_editpanel('custom') }
sub set_editpanel_default { set_editpanel('default')}
sub set_editpanel_none    { set_editpanel('none')   }
sub set_editpanel {
	my $mode = shift;
	$mode = 'custom' unless $mode;
	Kepher::App::EditPanel::_get_config()->{(CFGROOT)}{'visible'} = $mode;
	connect_editpanel();
}

1;
