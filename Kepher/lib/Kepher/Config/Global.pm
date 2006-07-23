package PCE::Config::Global;
$VERSION = '0.12';

# main config file handling

use strict;


sub load_autosaved {
	my @main_conf_files = (
		$PCE::internal{file}{config}{auto},
		$PCE::internal{file}{config}{auto}.'~',
		$PCE::internal{file}{config}{default}
	);

	# try first auto config file, than backup, then defaults
	for my $configfile (@main_conf_files) {
		$configfile = $PCE::internal{path}{config} . $configfile;
		if ( -e $configfile ) {
			%PCE::config = %{ PCE::Config::File::load($configfile) };
			if (%PCE::config) { last; }
			else              { rename $configfile, 'failed.' . $configfile; }
		}
	}

	# emergency program if configs missing
	unless (%PCE::config) {
		require PCE::Config::Embedded;
		%PCE::config = %{&PCE::Config::Embedded::get_global_settings};
	}
}

sub save_autosaved {
	my $config_path = $PCE::internal{path}{config};
	my $config_file = $config_path . $PCE::internal{file}{config}{auto};
	rename $config_file, $config_file . '~';
	PCE::Config::File::store( $config_file, \%PCE::config );
}

# sub that can be called during the app is running
sub open_current_file {
	require Cwd;
	PCE::Document::Internal::add( Cwd::getcwd().'/'.
		$PCE::internal{path}{config}. $PCE::internal{file}{config}{auto} );
	save_current();
	PCE::File::reload_current();
}

sub load_backup_file {
	reload($PCE::internal{path}{config}.$PCE::internal{file}{config}{auto}.'~')
}

sub load_default_file {
	reload( $PCE::internal{path}{config}.$PCE::internal{file}{config}{default} )
}

sub load_from {
	my $filename = PCE::Dialog::get_file_open(
		PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'config_file'}{'load'},
		$PCE::internal{path}{config} . 'general/',
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	&reload($filename) if ( -e $filename );
}

sub refresh {
	PCE::App::Window::save_positions();
	PCE::Document::Internal::save_properties();
	PCE::Edit::Bookmark::save_all();
}

sub evaluate {
	PCE::App::EventList::delete_all();
	PCE::Config::Interface::load_data();

	# set interna to default
	$PCE::app{'GUI'}{'masterID'}                    = 20;
	$PCE::internal{'dialog'}{'control'}             = 0;
	PCE::Edit::Search::_init_history();
	PCE::Edit::Search::_refresh_search_flags();
	PCE::Config::_build_fileendings2syntaxstyle_map();
	PCE::Config::_build_fileendings_filterstring();

	# main window components
	PCE::App::CommandList::eval_data();
	PCE::App::Window::apply_settings();
	PCE::App::ContextMenu::create_all();
	PCE::App::MenuBar::create();
	PCE::App::MainToolBar::create();
	PCE::App::SearchBar::create();
	PCE::App::TabBar::create();
	PCE::App::StatusBar::create();
	PCE::App::assemble_layout();

	PCE::App::ContextMenu::connect_all();
	PCE::App::STC::apply_settings();
	PCE::Edit::Bookmark::define_marker();
	PCE::App::EventList::init();
	PCE::App::Events::set_table();

	PCE::Config::Interface::del_temp_data();
	PCE::App::CommandList::del_data();

	return 1;
}

sub reload {
	my $configfile = shift;
	$configfile = $PCE::internal{path}{config}.$PCE::internal{file}{config}{auto}
		unless $configfile;
	if ( -e $configfile ) {
		PCE::Document::Internal::save_properties();
		my %test_hash = %{ PCE::Config::File::load($configfile) };
		if (%test_hash) {
			%PCE::config = %test_hash;
			&evaluate;
			PCE::Document::Internal::eval_properties();
		} else {
			&save();
			&PCE::File::reload_current;
		}
	} else {
		my $err_msg = $PCE::localisation{'dialog'}{'error'};
		PCE::Dialog::warning_box( undef, 
			$err_msg->{'file_find'}."\n $configfile",$err_msg->{'config_read'});
	}
}

sub reload_current {
	reload($PCE::internal{path}{config} . $PCE::internal{file}{config}{auto} );
}

sub reload_config_file {
	require Cwd;
	my $config_file = shift;
	my $config_path = Cwd::getcwd().'/'.$PCE::internal{path}{config};#
	my $autosave = $config_path . $PCE::internal{file}{config}{auto};
	$config_file = $autosave if ( ( !$config_file ) or ( !-e $config_file ) );
	$config_file = PCE::Document::Internal::standartize_path_slashes($config_file);

	if ( $config_path eq substr( $config_file, 0, length $config_path ) ){
		my $conf =\%{$PCE::config{app}};
		#$config_file = substr( $config_file, length $config_path );
		reload($autosave) if $config_file eq $autosave;
		reload($autosave) if $config_file eq $conf->{localisation_file};
		#&PCE::App::Visual::load_menubar if ( $config_file eq $conf->{menubar}{file} );
		#&PCE::App::Visual::load_toolbar if ( $config_file eq $conf->{toolbar}{file} );
		#&PCE::App::Visual::load_edit_contextmenu
			#if $config_file eq $PCE::config{editpanel}{contextmenu}{file};
		#&PCE::App::Visual::load_tab_contextmenu
		#	if $config_file eq $app_conf->{tabbar}{contextmenu}{file};
		#&PCE::App::Visual::load_status_contextmenu
			#if $config_file eq $app_conf->{statusbar}{contextmenu}{file};
	}
}

#
sub save {
	my $configfile = shift;
	$configfile = $PCE::internal{path}{config} . $PCE::internal{file}{config}{auto}
		if $configfile ;
	refresh();
	PCE::Config::File::store( $configfile, \%PCE::config );
}

sub save_as {
	my $filename = PCE::Dialog::get_file_save(
		PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'config_file'}{'save'},
		$PCE::internal{'path'}{'config'} . 'general',
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	save($filename) if ( length($filename) > 0 );
}

sub save_current {
	save( $PCE::internal{path}{config} . $PCE::internal{file}{config}{auto} );
}

#
sub merge_with {
	my $app_win    = PCE::App::Window::_get();
	my $filename = PCE::Dialog::get_file_open( $app_win,
		$PCE::localisation{'dialog'}{'config_file'}{'load'},
		$PCE::internal{path}{config} . 'general/sub',
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	load_subconfig($filename);
}


#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		require Hash::Merge;
		Hash::Merge::set_behavior('LEFT_PRECEDENT');
		%PCE::config =
			%{Hash::Merge::merge(PCE::Config::File::load($file), \%PCE::config )};
		refresh();
		evaluate();
		PCE::App::TabBar::refresh_all_label();
		PCE::Document::Internal::eval_properties();
	}
}

sub set_lang_2_cesky_utf {
	load_subconfig( $PCE::internal{path}{config}
		. 'global/sub/localisation/cesky_utf.conf' );
}

sub set_lang_2_deutsch_utf {
	load_subconfig( $PCE::internal{path}{config}
		. 'global/sub/localisation/deutsch_utf.conf' );
}

sub set_lang_2_deutsch_iso {
	load_subconfig( $PCE::internal{path}{config}
		. 'global/sub/localisation/deutsch_iso.conf' );
}

sub set_lang_2_deutsch {
	load_subconfig( $PCE::internal{path}{config}
		. 'global/sub/localisation/deutsch.conf' );
}

sub set_lang_2_english {
	load_subconfig( $PCE::internal{path}{config}
		. 'global/sub/localisation/english.conf' );
}

1;
