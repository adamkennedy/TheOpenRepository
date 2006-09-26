package Kephra::Config::Global;
$VERSION = '0.13';

# handling main config file

use strict;


sub load_autosaved {
	my @main_conf_files = (
		$Kephra::temp{file}{config}{auto},
		$Kephra::temp{file}{config}{auto}.'~',
		$Kephra::temp{file}{config}{default}
	);

	# try first auto config file, than backup, then defaults
	for my $configfile (@main_conf_files) {
		$configfile = $Kephra::temp{path}{config} . $configfile;
		if ( -e $configfile ) {
			%Kephra::config = %{ Kephra::Config::File::load($configfile) };
			if (%Kephra::config) { last }
			else                 { rename $configfile, 'failed.' . $configfile }
		}
	}

	# emergency program if configs missing
	unless (%Kephra::config) {
		require Kephra::Config::Embedded;
		%Kephra::config = %{&Kephra::Config::Embedded::get_global_settings};
	}
}

sub save_autosaved {
	my $config_path = $Kephra::temp{path}{config};
	my $config_file = $config_path . $Kephra::temp{file}{config}{auto};
	rename $config_file, $config_file . '~';
	Kephra::Config::File::store( $config_file, \%Kephra::config );
}

# sub that can be called during the app is running
sub open_current_file {
	require Cwd;
	Kephra::Document::Internal::add( Cwd::getcwd().'/'.
		$Kephra::temp{path}{config}. $Kephra::temp{file}{config}{auto} );
	save_current();
	Kephra::File::reload_current();
}

sub load_backup_file {
	reload($Kephra::temp{path}{config}.$Kephra::temp{file}{config}{auto}.'~')
}

sub load_default_file {
	reload( $Kephra::temp{path}{config}.$Kephra::temp{file}{config}{default} )
}

sub load_from {
	my $filename = Kephra::Dialog::get_file_open(
		Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'config_file'}{'load'},
		$Kephra::temp{path}{config} . 'general/',
		$Kephra::temp{'file'}{'filterstring'}{'config'}
	);
	&reload($filename) if ( -e $filename );
}

sub refresh {
	Kephra::App::Window::save_positions();
	Kephra::Document::Internal::save_properties();
	Kephra::Edit::Bookmark::save_all();
}

sub evaluate {
	my $t0 = new Benchmark;

	Kephra::App::EventList::delete_all();
	Kephra::Config::Interface::load_data();
	my $t1 = new Benchmark;
print " iface cfg:", Benchmark::timestr( Benchmark::timediff( $t1, $t0 ) ), "\n";

	# set interna to default
	$Kephra::app{'GUI'}{'masterID'}         = 20;
	$Kephra::temp{'dialog'}{'control'}  = 0;
	Kephra::Edit::Search::_init_history();
	Kephra::Edit::Search::_refresh_search_flags();
	Kephra::Config::build_fileendings2syntaxstyle_map();
	Kephra::Config::build_fileendings_filterstring();
	my $t2 = new Benchmark;
print " prep. data:", Benchmark::timestr( Benchmark::timediff( $t2, $t1 ) ), "\n";

	# main window components
	Kephra::App::CommandList::eval_data();
	Kephra::App::Window::apply_settings();
	Kephra::App::ContextMenu::create_all();
	Kephra::App::MenuBar::create();
	Kephra::App::MainToolBar::create();
	Kephra::App::SearchBar::create();
	Kephra::App::TabBar::create();
	Kephra::App::StatusBar::create();
	Kephra::App::assemble_layout();
	my $t3 = new Benchmark;
print " create gui:", Benchmark::timestr( Benchmark::timediff( $t3, $t2 ) ), "\n";

	Kephra::App::ContextMenu::connect_all();
	Kephra::App::EditPanel::apply_settings();
	Kephra::Edit::Bookmark::define_marker();
	Kephra::App::EventList::init();
	Kephra::App::Events::set_table();
	my $t4 = new Benchmark;
print " apply sets:", Benchmark::timestr( Benchmark::timediff( $t4, $t3 ) ), "\n";

	Kephra::Config::Interface::del_temp_data();
	Kephra::App::CommandList::del_temp_data();

	return 1;
}

sub reload {
	my $configfile = shift;
	$configfile = $Kephra::temp{path}{config}.$Kephra::temp{file}{config}{auto}
		unless $configfile;
	if ( -e $configfile ) {
		Kephra::Document::Internal::save_properties();
		my %test_hash = %{ Kephra::Config::File::load($configfile) };
		if (%test_hash) {
			%Kephra::config = %test_hash;
			&evaluate;
			Kephra::Document::Internal::eval_properties();
		} else {
			&save();
			&Kephra::File::reload_current;
		}
	} else {
		my $err_msg = $Kephra::localisation{'dialog'}{'error'};
		Kephra::Dialog::warning_box( undef, 
			$err_msg->{'file_find'}."\n $configfile",$err_msg->{'config_read'});
	}
}

sub reload_current {
	reload($Kephra::temp{path}{config} . $Kephra::temp{file}{config}{auto} );
}

sub reload_config_file {
	require Cwd;
	my $config_file = shift;
	my $config_path = Cwd::getcwd().'/'.$Kephra::temp{path}{config};#
	my $autosave = $config_path . $Kephra::temp{file}{config}{auto};
	$config_file = $autosave if ( ( !$config_file ) or ( !-e $config_file ) );
	$config_file = Kephra::Document::Internal::standartize_path_slashes($config_file);

	if ( $config_path eq substr( $config_file, 0, length $config_path ) ){
		my $conf =\%{$Kephra::config{app}};
		#$config_file = substr( $config_file, length $config_path );
		reload($autosave) if $config_file eq $autosave;
		reload($autosave) if $config_file eq $conf->{localisation_file};
		#&Kephra::App::Visual::load_menubar if ( $config_file eq $conf->{menubar}{file} );
		#&Kephra::App::Visual::load_toolbar if ( $config_file eq $conf->{toolbar}{file} );
		#&Kephra::App::Visual::load_edit_contextmenu
			#if $config_file eq $Kephra::config{editpanel}{contextmenu}{file};
		#&Kephra::App::Visual::load_tab_contextmenu
		#	if $config_file eq $app_conf->{tabbar}{contextmenu}{file};
		#&Kephra::App::Visual::load_status_contextmenu
			#if $config_file eq $app_conf->{statusbar}{contextmenu}{file};
	}
}

#
sub save {
	my $configfile = shift;
	$configfile = $Kephra::temp{path}{config} .
		$Kephra::temp{file}{config}{auto}
		unless $configfile ;
	refresh();
	Kephra::Config::File::store( $configfile, \%Kephra::config );
}

sub save_as {
	my $filename = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'config_file'}{'save'},
		$Kephra::temp{'path'}{'config'} . 'general',
		$Kephra::temp{'file'}{'filterstring'}{'config'}
	);
	save($filename) if ( length($filename) > 0 );
}

sub save_current {
	save( $Kephra::temp{path}{config} . $Kephra::temp{file}{config}{auto} );
}

#
sub merge_with {
	my $app_win    = Kephra::App::Window::_get();
	my $filename = Kephra::Dialog::get_file_open( $app_win,
		$Kephra::localisation{'dialog'}{'config_file'}{'load'},
		$Kephra::temp{path}{config} . 'general/sub',
		$Kephra::temp{'file'}{'filterstring'}{'config'}
	);
	load_subconfig($filename);
}


#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		%Kephra::config = %{ Kephra::Config::Tree::merge
			(Kephra::Config::File::load($file), \%Kephra::config) };
		refresh();
		evaluate();
		Kephra::App::TabBar::refresh_all_label();
		Kephra::Document::Internal::eval_properties();
	}
}

sub set_lang_2_cesky_utf {
	load_subconfig( $Kephra::temp{path}{config}
		. 'global/sub/localisation/cesky_utf.conf' );
}

sub set_lang_2_deutsch_utf {
	load_subconfig( $Kephra::temp{path}{config}
		. 'global/sub/localisation/deutsch_utf.conf' );
}

sub set_lang_2_deutsch_iso {
	load_subconfig( $Kephra::temp{path}{config}
		. 'global/sub/localisation/deutsch_iso.conf' );
}

sub set_lang_2_deutsch {
	load_subconfig( $Kephra::temp{path}{config}
		. 'global/sub/localisation/deutsch.conf' );
}

sub set_lang_2_english {
	load_subconfig( $Kephra::temp{path}{config}
		. 'global/sub/localisation/english.conf' );
}

1;
