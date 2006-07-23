package KEPHER::Config::Global;
$VERSION = '0.12';

# main config file handling

use strict;


sub load_autosaved {
	my @main_conf_files = (
		$KEPHER::internal{file}{config}{auto},
		$KEPHER::internal{file}{config}{auto}.'~',
		$KEPHER::internal{file}{config}{default}
	);

	# try first auto config file, than backup, then defaults
	for my $configfile (@main_conf_files) {
		$configfile = $KEPHER::internal{path}{config} . $configfile;
		if ( -e $configfile ) {
			%KEPHER::config = %{ KEPHER::Config::File::load($configfile) };
			if (%KEPHER::config) { last; }
			else              { rename $configfile, 'failed.' . $configfile; }
		}
	}

	# emergency program if configs missing
	unless (%KEPHER::config) {
		require KEPHER::Config::Embedded;
		%KEPHER::config = %{&KEPHER::Config::Embedded::get_global_settings};
	}
}

sub save_autosaved {
	my $config_path = $KEPHER::internal{path}{config};
	my $config_file = $config_path . $KEPHER::internal{file}{config}{auto};
	rename $config_file, $config_file . '~';
	KEPHER::Config::File::store( $config_file, \%KEPHER::config );
}

# sub that can be called during the app is running
sub open_current_file {
	require Cwd;
	KEPHER::Document::Internal::add( Cwd::getcwd().'/'.
		$KEPHER::internal{path}{config}. $KEPHER::internal{file}{config}{auto} );
	save_current();
	KEPHER::File::reload_current();
}

sub load_backup_file {
	reload($KEPHER::internal{path}{config}.$KEPHER::internal{file}{config}{auto}.'~')
}

sub load_default_file {
	reload( $KEPHER::internal{path}{config}.$KEPHER::internal{file}{config}{default} )
}

sub load_from {
	my $filename = KEPHER::Dialog::get_file_open(
		KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'config_file'}{'load'},
		$KEPHER::internal{path}{config} . 'general/',
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	&reload($filename) if ( -e $filename );
}

sub refresh {
	KEPHER::App::Window::save_positions();
	KEPHER::Document::Internal::save_properties();
	KEPHER::Edit::Bookmark::save_all();
}

sub evaluate {
	KEPHER::App::EventList::delete_all();
	KEPHER::Config::Interface::load_data();

	# set interna to default
	$KEPHER::app{'GUI'}{'masterID'}                    = 20;
	$KEPHER::internal{'dialog'}{'control'}             = 0;
	KEPHER::Edit::Search::_init_history();
	KEPHER::Edit::Search::_refresh_search_flags();
	KEPHER::Config::_build_fileendings2syntaxstyle_map();
	KEPHER::Config::_build_fileendings_filterstring();

	# main window components
	KEPHER::App::CommandList::eval_data();
	KEPHER::App::Window::apply_settings();
	KEPHER::App::ContextMenu::create_all();
	KEPHER::App::MenuBar::create();
	KEPHER::App::MainToolBar::create();
	KEPHER::App::SearchBar::create();
	KEPHER::App::TabBar::create();
	KEPHER::App::StatusBar::create();
	KEPHER::App::assemble_layout();

	KEPHER::App::ContextMenu::connect_all();
	KEPHER::App::STC::apply_settings();
	KEPHER::Edit::Bookmark::define_marker();
	KEPHER::App::EventList::init();
	KEPHER::App::Events::set_table();

	KEPHER::Config::Interface::del_temp_data();
	KEPHER::App::CommandList::del_data();

	return 1;
}

sub reload {
	my $configfile = shift;
	$configfile = $KEPHER::internal{path}{config}.$KEPHER::internal{file}{config}{auto}
		unless $configfile;
	if ( -e $configfile ) {
		KEPHER::Document::Internal::save_properties();
		my %test_hash = %{ KEPHER::Config::File::load($configfile) };
		if (%test_hash) {
			%KEPHER::config = %test_hash;
			&evaluate;
			KEPHER::Document::Internal::eval_properties();
		} else {
			&save();
			&KEPHER::File::reload_current;
		}
	} else {
		my $err_msg = $KEPHER::localisation{'dialog'}{'error'};
		KEPHER::Dialog::warning_box( undef, 
			$err_msg->{'file_find'}."\n $configfile",$err_msg->{'config_read'});
	}
}

sub reload_current {
	reload($KEPHER::internal{path}{config} . $KEPHER::internal{file}{config}{auto} );
}

sub reload_config_file {
	require Cwd;
	my $config_file = shift;
	my $config_path = Cwd::getcwd().'/'.$KEPHER::internal{path}{config};#
	my $autosave = $config_path . $KEPHER::internal{file}{config}{auto};
	$config_file = $autosave if ( ( !$config_file ) or ( !-e $config_file ) );
	$config_file = KEPHER::Document::Internal::standartize_path_slashes($config_file);

	if ( $config_path eq substr( $config_file, 0, length $config_path ) ){
		my $conf =\%{$KEPHER::config{app}};
		#$config_file = substr( $config_file, length $config_path );
		reload($autosave) if $config_file eq $autosave;
		reload($autosave) if $config_file eq $conf->{localisation_file};
		#&KEPHER::App::Visual::load_menubar if ( $config_file eq $conf->{menubar}{file} );
		#&KEPHER::App::Visual::load_toolbar if ( $config_file eq $conf->{toolbar}{file} );
		#&KEPHER::App::Visual::load_edit_contextmenu
			#if $config_file eq $KEPHER::config{editpanel}{contextmenu}{file};
		#&KEPHER::App::Visual::load_tab_contextmenu
		#	if $config_file eq $app_conf->{tabbar}{contextmenu}{file};
		#&KEPHER::App::Visual::load_status_contextmenu
			#if $config_file eq $app_conf->{statusbar}{contextmenu}{file};
	}
}

#
sub save {
	my $configfile = shift;
	$configfile = $KEPHER::internal{path}{config} . $KEPHER::internal{file}{config}{auto}
		if $configfile ;
	refresh();
	KEPHER::Config::File::store( $configfile, \%KEPHER::config );
}

sub save_as {
	my $filename = KEPHER::Dialog::get_file_save(
		KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'config_file'}{'save'},
		$KEPHER::internal{'path'}{'config'} . 'general',
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	save($filename) if ( length($filename) > 0 );
}

sub save_current {
	save( $KEPHER::internal{path}{config} . $KEPHER::internal{file}{config}{auto} );
}

#
sub merge_with {
	my $app_win    = KEPHER::App::Window::_get();
	my $filename = KEPHER::Dialog::get_file_open( $app_win,
		$KEPHER::localisation{'dialog'}{'config_file'}{'load'},
		$KEPHER::internal{path}{config} . 'general/sub',
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	load_subconfig($filename);
}


#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		require Hash::Merge;
		Hash::Merge::set_behavior('LEFT_PRECEDENT');
		%KEPHER::config =
			%{Hash::Merge::merge(KEPHER::Config::File::load($file), \%KEPHER::config )};
		refresh();
		evaluate();
		KEPHER::App::TabBar::refresh_all_label();
		KEPHER::Document::Internal::eval_properties();
	}
}

sub set_lang_2_cesky_utf {
	load_subconfig( $KEPHER::internal{path}{config}
		. 'global/sub/localisation/cesky_utf.conf' );
}

sub set_lang_2_deutsch_utf {
	load_subconfig( $KEPHER::internal{path}{config}
		. 'global/sub/localisation/deutsch_utf.conf' );
}

sub set_lang_2_deutsch_iso {
	load_subconfig( $KEPHER::internal{path}{config}
		. 'global/sub/localisation/deutsch_iso.conf' );
}

sub set_lang_2_deutsch {
	load_subconfig( $KEPHER::internal{path}{config}
		. 'global/sub/localisation/deutsch.conf' );
}

sub set_lang_2_english {
	load_subconfig( $KEPHER::internal{path}{config}
		. 'global/sub/localisation/english.conf' );
}

1;
