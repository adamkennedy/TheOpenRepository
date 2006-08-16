package Kepher::Config::Global;
$VERSION = '0.12';

# main config file handling

use strict;


sub load_autosaved {
	my @main_conf_files = (
		$Kepher::internal{file}{config}{auto},
		$Kepher::internal{file}{config}{auto}.'~',
		$Kepher::internal{file}{config}{default}
	);

	# try first auto config file, than backup, then defaults
	for my $configfile (@main_conf_files) {
		$configfile = $Kepher::internal{path}{config} . $configfile;
		if ( -e $configfile ) {
			%Kepher::config = %{ Kepher::Config::File::load($configfile) };
			if (%Kepher::config) { last; }
			else              { rename $configfile, 'failed.' . $configfile; }
		}
	}

	# emergency program if configs missing
	unless (%Kepher::config) {
		require Kepher::Config::Embedded;
		%Kepher::config = %{&Kepher::Config::Embedded::get_global_settings};
	}
}

sub save_autosaved {
	my $config_path = $Kepher::internal{path}{config};
	my $config_file = $config_path . $Kepher::internal{file}{config}{auto};
	rename $config_file, $config_file . '~';
	Kepher::Config::File::store( $config_file, \%Kepher::config );
}

# sub that can be called during the app is running
sub open_current_file {
	require Cwd;
	Kepher::Document::Internal::add( Cwd::getcwd().'/'.
		$Kepher::internal{path}{config}. $Kepher::internal{file}{config}{auto} );
	save_current();
	Kepher::File::reload_current();
}

sub load_backup_file {
	reload($Kepher::internal{path}{config}.$Kepher::internal{file}{config}{auto}.'~')
}

sub load_default_file {
	reload( $Kepher::internal{path}{config}.$Kepher::internal{file}{config}{default} )
}

sub load_from {
	my $filename = Kepher::Dialog::get_file_open(
		Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'config_file'}{'load'},
		$Kepher::internal{path}{config} . 'general/',
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	&reload($filename) if ( -e $filename );
}

sub refresh {
	Kepher::App::Window::save_positions();
	Kepher::Document::Internal::save_properties();
	Kepher::Edit::Bookmark::save_all();
}

sub evaluate {
	Kepher::App::EventList::delete_all();
	Kepher::Config::Interface::load_data();

	# set interna to default
	$Kepher::app{'GUI'}{'masterID'}                    = 20;
	$Kepher::internal{'dialog'}{'control'}             = 0;
	Kepher::Edit::Search::_init_history();
	Kepher::Edit::Search::_refresh_search_flags();
	Kepher::Config::_build_fileendings2syntaxstyle_map();
	Kepher::Config::_build_fileendings_filterstring();

	# main window components
	Kepher::App::CommandList::eval_data();
	Kepher::App::Window::apply_settings();
	Kepher::App::ContextMenu::create_all();
	Kepher::App::MenuBar::create();
	Kepher::App::MainToolBar::create();
	Kepher::App::SearchBar::create();
	Kepher::App::TabBar::create();
	Kepher::App::StatusBar::create();
	Kepher::App::assemble_layout();

	Kepher::App::ContextMenu::connect_all();
	Kepher::App::EditPanel::apply_settings();
	Kepher::Edit::Bookmark::define_marker();
	Kepher::App::EventList::init();
	Kepher::App::Events::set_table();

	Kepher::Config::Interface::del_temp_data();
	Kepher::App::CommandList::del_data();

	return 1;
}

sub reload {
	my $configfile = shift;
	$configfile = $Kepher::internal{path}{config}.$Kepher::internal{file}{config}{auto}
		unless $configfile;
	if ( -e $configfile ) {
		Kepher::Document::Internal::save_properties();
		my %test_hash = %{ Kepher::Config::File::load($configfile) };
		if (%test_hash) {
			%Kepher::config = %test_hash;
			&evaluate;
			Kepher::Document::Internal::eval_properties();
		} else {
			&save();
			&Kepher::File::reload_current;
		}
	} else {
		my $err_msg = $Kepher::localisation{'dialog'}{'error'};
		Kepher::Dialog::warning_box( undef, 
			$err_msg->{'file_find'}."\n $configfile",$err_msg->{'config_read'});
	}
}

sub reload_current {
	reload($Kepher::internal{path}{config} . $Kepher::internal{file}{config}{auto} );
}

sub reload_config_file {
	require Cwd;
	my $config_file = shift;
	my $config_path = Cwd::getcwd().'/'.$Kepher::internal{path}{config};#
	my $autosave = $config_path . $Kepher::internal{file}{config}{auto};
	$config_file = $autosave if ( ( !$config_file ) or ( !-e $config_file ) );
	$config_file = Kepher::Document::Internal::standartize_path_slashes($config_file);

	if ( $config_path eq substr( $config_file, 0, length $config_path ) ){
		my $conf =\%{$Kepher::config{app}};
		#$config_file = substr( $config_file, length $config_path );
		reload($autosave) if $config_file eq $autosave;
		reload($autosave) if $config_file eq $conf->{localisation_file};
		#&Kepher::App::Visual::load_menubar if ( $config_file eq $conf->{menubar}{file} );
		#&Kepher::App::Visual::load_toolbar if ( $config_file eq $conf->{toolbar}{file} );
		#&Kepher::App::Visual::load_edit_contextmenu
			#if $config_file eq $Kepher::config{editpanel}{contextmenu}{file};
		#&Kepher::App::Visual::load_tab_contextmenu
		#	if $config_file eq $app_conf->{tabbar}{contextmenu}{file};
		#&Kepher::App::Visual::load_status_contextmenu
			#if $config_file eq $app_conf->{statusbar}{contextmenu}{file};
	}
}

#
sub save {
	my $configfile = shift;
	$configfile = $Kepher::internal{path}{config} . $Kepher::internal{file}{config}{auto}
		if $configfile ;
	refresh();
	Kepher::Config::File::store( $configfile, \%Kepher::config );
}

sub save_as {
	my $filename = Kepher::Dialog::get_file_save(
		Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'config_file'}{'save'},
		$Kepher::internal{'path'}{'config'} . 'general',
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	save($filename) if ( length($filename) > 0 );
}

sub save_current {
	save( $Kepher::internal{path}{config} . $Kepher::internal{file}{config}{auto} );
}

#
sub merge_with {
	my $app_win    = Kepher::App::Window::_get();
	my $filename = Kepher::Dialog::get_file_open( $app_win,
		$Kepher::localisation{'dialog'}{'config_file'}{'load'},
		$Kepher::internal{path}{config} . 'general/sub',
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	load_subconfig($filename);
}


#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		require Hash::Merge;
		Hash::Merge::set_behavior('LEFT_PRECEDENT');
		%Kepher::config =
			%{Hash::Merge::merge(Kepher::Config::File::load($file), \%Kepher::config )};
		refresh();
		evaluate();
		Kepher::App::TabBar::refresh_all_label();
		Kepher::Document::Internal::eval_properties();
	}
}

sub set_lang_2_cesky_utf {
	load_subconfig( $Kepher::internal{path}{config}
		. 'global/sub/localisation/cesky_utf.conf' );
}

sub set_lang_2_deutsch_utf {
	load_subconfig( $Kepher::internal{path}{config}
		. 'global/sub/localisation/deutsch_utf.conf' );
}

sub set_lang_2_deutsch_iso {
	load_subconfig( $Kepher::internal{path}{config}
		. 'global/sub/localisation/deutsch_iso.conf' );
}

sub set_lang_2_deutsch {
	load_subconfig( $Kepher::internal{path}{config}
		. 'global/sub/localisation/deutsch.conf' );
}

sub set_lang_2_english {
	load_subconfig( $Kepher::internal{path}{config}
		. 'global/sub/localisation/english.conf' );
}

1;
