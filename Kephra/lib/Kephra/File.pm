package Kephra::File;
$VERSION = '0.35';

# file save events, drag n drop files, file menu calls

use strict;
use Wx qw(wxYES wxNO wxCANCEL);

#
# event handling
#
sub savepoint_left {
	$Kephra::temp{'document'}{'modified'}++
		unless $Kephra::temp{'current_doc'}{'modified'};
	$Kephra::temp{'current_doc'}{'modified'} = 1;
	Kephra::App::TabBar::refresh_current_label()
		if $Kephra::config{'app'}{'tabbar'}{'info_symbol'};
	Kephra::App::EventList::trigger('document.savepoint');
}
sub savepoint_reached {
	$Kephra::temp{'document'}{'modified'}-- if 
		$Kephra::temp{'current_doc'}{'modified'};
	$Kephra::temp{'current_doc'}{'modified'} = 0;
	Kephra::App::TabBar::refresh_current_label();
	Kephra::App::EventList::trigger('document.savepoint');
}

sub can_save     { $Kephra::temp{'current_doc'}{'modified'} }
sub can_save_all { $Kephra::temp{'document'}{'modified'} }

#
# add file per drag and drop
#
sub add_dropped {
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : Kephra::Document::Internal::add($_) for $event->GetFiles;
}

# add dir per drag and drop
sub add_dir{
	my $dir = shift;
	opendir (DIR, $dir);
	my @dir_items = readdir(DIR);
	closedir(DIR);
	my $path;
	my $recursive = $Kephra::config{'file'}{'open'}{'dir_recursive'};

	foreach (@dir_items) {
		$path = "$dir/$_";
		if (-d $path) {
			next if not $recursive or $_ eq '.' or $_ eq '..';
			add_dir($path);
		} else { Kephra::Document::Internal::add($path) }
	}
}

#
# file menu calls
#
sub new {
	my $doc_nr = Kephra::Document::Internal::new_if_allowed('new');
	Kephra::Document::Internal::reset();
	Kephra::Document::_set_current_nr( $doc_nr );
}


sub open {
	# buttons dont freeze while computing
	Kephra::App::_get()->Yield();

	# file selector dialog
	my $files = Kephra::Dialog::get_files_open( Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'file'}{'open'},
		$Kephra::config{'file'}{'current'}{'directory'},
		$Kephra::temp{'file'}{'filterstring'}{'all'}
	);

	# opening selected files
	if (ref $files eq 'ARRAY') { Kephra::Document::Internal::add($_) for @$files }
}


sub reload_current {
	my $file_path = Kephra::Document::_get_current_file_path();
	my $nr = Kephra::Document::_get_current_nr();
	if ($file_path and -e $file_path){
		my $ep = Kephra::App::EditPanel::_get();
		Kephra::Document::Internal::save_properties();
		$ep->BeginUndoAction;
		$ep->SetText("");
		Kephra::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		Kephra::Document::Internal::eval_properties();
		Kephra::App::EditPanel::Margin::autosize_line_number()
			if ($Kephra::config{'editpanel'}{'margin'}{'linenumber'}{'autosize'}
			and $Kephra::config{'editpanel'}{'margin'}{'linenumber'}{'width'} );
	} else {}
}


sub reload_all {
	my $doc_nr = Kephra::Document::_get_current_file_path();
	for ( 0 .. Kephra::Document::_get_last_nr() ) {
		Kephra::Document::Change::to_number($_);
		reload_current();
	}
	Kephra::Document::Change::to_number($doc_nr);
}


sub insert {
	my $insertfilename = Kephra::Dialog::get_file_open( Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'file'}{'insert'},
		$Kephra::config{'file'}{'current'}{'directory'},
		$Kephra::temp{'file'}{'filterstring'}{'all'}
	);
	if ( -e $insertfilename ) {
		my $ep = Kephra::App::EditPanel::_get();
		my $text = Kephra::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = Kephra::App::EditPanel::_get();
	my $file_name   = Kephra::Document::_get_current_file_path();
	my $save_config = $Kephra::config{'file'}{'save'};
	if ( $ep->GetModify == 1 or $save_config->{'unchanged'} ) {
		if ( $file_name and -e $file_name ) {
			if (not -w $file_name ) {
				my $err_msg = $Kephra::localisation{'dialog'}{'error'};
				Kephra::Dialog::warning_box( Kephra::App::Window::_get(),
					$err_msg->{write_protected}.'\n'.$err_msg->{write_protected2},
					$err_msg->{'file'} );
				save_as();
			} else {
				rename $file_name, $file_name . '~'
					if $Kephra::config{'file'}{'save'}{'tilde_backup'} == 1;
				Kephra::File::IO::write_buffer( $file_name, $ep->GetText );
				Kephra::Config::Global::reload_config_file($file_name)
					if $save_config->{'reload_config'} == 1;
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'file'}{'save_as'},
		$Kephra::config{'file'}{'current'}{'directory'},
		$Kephra::temp{'file'}{'filterstring'}{'all'}
	);
	if (    length($file_name) > 0
		and Kephra::Document::Internal::check_b4_overwite($file_name) ) {

		my $ep = Kephra::App::EditPanel::_get();
		$Kephra::temp{'document'}{'loaded'}++
			if length(Kephra::Document::_get_current_file_path) == 0;

		Kephra::Document::set_file_path($file_name);
		Kephra::File::IO::write_buffer($file_name, $ep->GetText );
		$ep->SetSavePoint;
		Kephra::Document::SyntaxMode::change_to('auto');
		Kephra::Document::Internal::save_properties();
		$Kephra::config{'file'}{'current'}{'directory'} = 
			$Kephra::temp{'current_doc'}{'directory'};
		Kephra::App::EventList::trigger('document.list');
	}
}


sub save_copy_as {
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'file'}{'save_copy_as'},
		$Kephra::config{'file'}{'current'}{'directory'},
		$Kephra::temp{'file'}{'filterstring'}{'all'} );
	Kephra::File::IO::write_buffer
		( $file_name, Kephra::App::EditPanel::_get()->GetText )
		if $file_name and Kephra::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{'dialog'}{'file'}{'rename'},
		$Kephra::config{'file'}{'current'}{'directory'},
		$Kephra::temp{'file'}{'filterstring'}{'all'} );
	if ($new_path_name){
		my $old_path_name = Kephra::Document::_get_current_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		Kephra::Document::set_file_path($new_path_name);
		Kephra::Document::SyntaxMode::change_to('auto');
		$Kephra::config{'file'}{'current'}{'directory'} = 
			$Kephra::temp{'current_doc'}{'directory'};
		Kephra::App::EventList::trigger('document.list');
	}
}


sub save_all {
	my $doc_nr = Kephra::Document::_get_current_nr();
	my $doc_data = $Kephra::temp{'document'}{'open'};
	Kephra::Document::Internal::save_properties();
	for ( 0 .. &Kephra::Document::_get_last_nr ) {
		if ($doc_data->[$_]{'modified'}){
			Kephra::Document::Internal::change_pointer($_);
			save_current();
		}
	}
	Kephra::Document::Internal::change_pointer($doc_nr);
	Kephra::Document::Internal::eval_properties($doc_nr);
}


sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = Kephra::App::EditPanel::_get();
	my $close_tab_nr = Kephra::Document::_get_current_nr();
	my $config       = $Kephra::config{'file'}{'save'};
	my $save_answer  = wxNO;

	# save text if options allow it
	if ($ep->GetModify == 1 or $config->{'unchanged'} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{'empty'} eq 1) {
			if ($config->{'b4_close'} eq 'ask' or $config->{'b4_close'} eq '2'){
				my $l10n = $Kephra::localisation{'dialog'}{'file'};
				$save_answer = Kephra::Dialog::get_confirm_3( Kephra::App::Window::_get(),
					$l10n->{'save_current'}, $l10n->{'close_unsaved'} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{'b4_close'} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

	# empty last document
	if ( $Kephra::temp{'document'}{'buffer'} == 1 ) {
		$Kephra::temp{'file'}{'current'}{'loaded'} = 0;
		Kephra::Document::Internal::reset();
	}

	# close document
	elsif ( $Kephra::temp{'document'}{'buffer'} > 1 ) {
		# select to which file nr to jump
		my $new_tab_nr = $close_tab_nr + 1;
		if ( defined $Kephra::document{'open'}[$new_tab_nr] ) {
			Kephra::Document::Change::to_number($new_tab_nr);
			$Kephra::document{'current_nr'}--;
		} else {
			$new_tab_nr -= 2;
			Kephra::Document::Change::to_number($new_tab_nr);
		}
		$Kephra::temp{'document'}{'buffer'}--;
		$Kephra::temp{'document'}{'loaded'}--
			if ( $Kephra::document{'open'}[$close_tab_nr]{'file_path'} );
		Kephra::App::TabBar::delete_page($close_tab_nr);

		# release file data of closed file
		if (ref $Kephra::document{'open'} eq 'ARRAY' ) {
			splice @{$Kephra::document{'open'}}, $close_tab_nr, 1;
			splice @{$Kephra::temp{'document'}{'open'}}, $close_tab_nr, 1;
		}

		#set correct internal pointer to new current file
		Kephra::Document::_set_current_nr($Kephra::document{'current_nr'});
		Kephra::App::TabBar::refresh_all_label();
	}
	#
	Kephra::App::EditPanel::Margin::reset_line_number_width();
	Kephra::App::EventList::trigger('document.list');
}


sub close_other {
	my $doc_nr = Kephra::Document::_get_current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : Kephra::Document::Change::to_number(1)
		for 0 .. Kephra::Document::_get_last_nr();
}


sub close_all { close_current() for 0 .. Kephra::Document::_get_last_nr() }

1;#Kephra::Dialog::msg_box(undef, $file_name, '');