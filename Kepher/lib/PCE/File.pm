package PCE::File;
$VERSION = '0.34';

# file save events, drag n drop files, file menu calls

use strict;
use Wx qw(wxYES wxNO wxCANCEL);

#
# event handling
#
sub savepoint_left {
	$PCE::internal{'document'}{'modified'}++
		unless $PCE::internal{'current_doc'}{'modified'};
	$PCE::internal{'current_doc'}{'modified'} = 1;
	PCE::App::TabBar::refresh_current_label()
		if $PCE::config{'app'}{'tabbar'}{'info_symbol'};
	PCE::App::EventList::trigger('document.savepoint');
}
sub savepoint_reached {
	$PCE::internal{'document'}{'modified'}-- if 
		$PCE::internal{'current_doc'}{'modified'};
	$PCE::internal{'current_doc'}{'modified'} = 0;
	PCE::App::TabBar::refresh_current_label();
	PCE::App::EventList::trigger('document.savepoint');
}

sub can_save     { $PCE::internal{'current_doc'}{'modified'} }
sub can_save_all { $PCE::internal{'document'}{'modified'} }

#
# add file per drag and drop
#
sub add_dropped {
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : PCE::Document::Internal::add($_) for $event->GetFiles;
}

# add dir per drag and drop
sub add_dir{
	my $dir = shift;
	opendir (DIR, $dir);
	my @dir_items = readdir(DIR);
	closedir(DIR);
	my $path;
	my $recursive = $PCE::config{'file'}{'open'}{'dir_recursive'};

	foreach (@dir_items) {
		$path = "$dir/$_";
		if (-d $path) {
			next if not $recursive or $_ eq '.' or $_ eq '..';
			add_dir($path);
		} else { PCE::Document::Internal::add($path) }
	}
}

#
# file menu calls
#
sub new {
	PCE::Document::Internal::new_if_allowed('new');
	PCE::Document::Internal::reset();
}


sub open {
	# buttons dont freeze while computing
	PCE::App::get_ref->Yield();

	# file selector dialog
	my $files = PCE::Dialog::get_files_open( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'open'},
		$PCE::config{'file'}{'current'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'all'}
	);

	# opening selected files
	if (ref $files eq 'ARRAY') { PCE::Document::Internal::add($_) for @$files }
}


sub reload_current {
	my $file_path = PCE::Document::_get_current_file_path();
	my $nr = PCE::Document::_get_current_nr();
	if ($file_path and -e $file_path){
		my $ep = PCE::App::STC::_get();
		PCE::Document::Internal::save_properties();
		$ep->BeginUndoAction;
		$ep->SetText("");
		PCE::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		PCE::Document::Internal::eval_properties();
		PCE::App::EditPanel::Margin::autosize_line_number()
			if ($PCE::config{'editpanel'}{'margin'}{'linenumber'}{'autosize'}
			and $PCE::config{'editpanel'}{'margin'}{'linenumber'}{'width'} );
	} else {}
}


sub reload_all {
	my $doc_nr = PCE::Document::_get_current_file_path();
	for ( 0 .. PCE::Document::_get_last_nr() ) {
		PCE::Document::Change::to_number($_);
		reload_current();
	}
	PCE::Document::Change::to_number($doc_nr);
}


sub insert {
	my $insertfilename = PCE::Dialog::get_file_open( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'insert'},
		$PCE::config{'file'}{'current'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'all'}
	);
	if ( -e $insertfilename ) {
		my $ep = PCE::App::STC::_get();
		my $text = PCE::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = PCE::App::STC::_get();
	my $file_name   = PCE::Document::_get_current_file_path();
	my $save_config = $PCE::config{'file'}{'save'};
	if ( $ep->GetModify == 1 or $save_config->{'unchanged'} ) {
		if ( $file_name and length($file_name) > 0 ) {
			if ( -e $file_name and not -w $file_name ) {
				my $err_msg = $PCE::localisation{'dialog'}{'error'};
				PCE::Dialog::warning_box( PCE::App::Window::_get(),
					$err_msg->{write_protected}.'\n'.$err_msg->{write_protected2},
					$err_msg->{'file'} );
				save_as();
			} else {
				rename $file_name, $file_name . '~'
					if $PCE::config{'file'}{'save'}{'tilde_backup'} == 1;
				PCE::File::IO::write_buffer( $file_name, $ep->GetText );
				PCE::Config::Global::reload_config_file($file_name)
					if $save_config->{'reload_config'} == 1;
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $filename = PCE::Dialog::get_file_save( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'save_as'},
		$PCE::config{'file'}{'current'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'all'}
	);
	if (length($filename) > 0
		and PCE::Document::Internal::check_b4_overwite($filename) ) {
		my $ep = PCE::App::STC::_get();
		$PCE::internal{'document'}{'loaded'}++
			if length($PCE::document{'current'}{'path'}) == 0;
		PCE::File::IO::write_buffer( $filename, $ep->GetText );
		PCE::Document::Internal::save_properties();
		PCE::Document::set_file_path($filename);
		PCE::Document::SyntaxMode::change_to('auto');
		$PCE::config{'file'}{'current'}{'directory'} = 
			$PCE::internal{'current_doc'}{'directory'};
		$ep->SetSavePoint;
		PCE::App::EventList::trigger('document.list');
	}
}


sub save_copy_as {
	my $file_name = PCE::Dialog::get_file_save( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'save_copy_as'},
		$PCE::config{'file'}{'current'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'all'} );
	PCE::File::IO::write_buffer( $file_name, PCE::App::STC::_get()->GetText )
		if $file_name and PCE::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = PCE::Dialog::get_file_save( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'rename'},
		$PCE::config{'file'}{'current'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'all'} );
	if ($new_path_name){
		my $old_path_name = PCE::Document::_get_current_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		PCE::Document::set_file_path($new_path_name);
	}
}


sub save_all {
	my $doc_nr = PCE::Document::_get_current_nr();
	my $doc_data = $PCE::internal{'document'}{'open'};
	PCE::Document::Internal::save_properties();
	for ( 0 .. &PCE::Document::_get_last_nr ) {
		if ($doc_data->[$_]{'modified'}){
			PCE::Document::Internal::change_pointer($_);
			save_current();
		}
	}
	PCE::Document::Internal::change_pointer($doc_nr);
	PCE::Document::Internal::eval_properties($doc_nr);
}


sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = PCE::App::STC::_get();
	my $close_tab_nr = PCE::Document::_get_current_nr();
	my $config       = $PCE::config{'file'}{'save'};
	my $save_answer  = wxNO;

	# save text if options allow it
	if ($ep->GetModify == 1 or $config->{'unchanged'} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{'empty'} eq 1) {
			if ($config->{'b4_close'} eq 'ask' or $config->{'b4_close'} eq '2'){
				my $l10n = $PCE::localisation{'dialog'}{'file'};
				$save_answer = PCE::Dialog::get_confirm_3( PCE::App::Window::_get(),
					$l10n->{'save_current'}, $l10n->{'close_unsaved'} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{'b4_close'} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

	# empty last document
	if ( $PCE::internal{'document'}{'buffer'} == 1 ) {
		$PCE::internal{'file'}{'current'}{'loaded'} = 0;
		PCE::Document::Internal::reset();
	}

	# close document
	elsif ( $PCE::internal{'document'}{'buffer'} > 1 ) {
		# select to which file nr to jump
		my $new_tab_nr = $close_tab_nr + 1;
		if ( defined $PCE::document{'open'}[$new_tab_nr] ) {
			PCE::Document::Change::to_number($new_tab_nr);
			$PCE::document{'current_nr'}--;
		} else {
			$new_tab_nr -= 2;
			PCE::Document::Change::to_number($new_tab_nr);
		}
		$PCE::internal{'document'}{'buffer'}--;
		$PCE::internal{'document'}{'loaded'}--
			if ( $PCE::document{'open'}[$close_tab_nr]{'path'} );
		PCE::App::TabBar::delete_page($close_tab_nr);

		# release file data of closed file
		if (ref $PCE::document{'open'} eq 'ARRAY' ) {
			splice @{$PCE::document{'open'}}, $close_tab_nr, 1;
			splice @{$PCE::internal{'document'}{'open'}}, $close_tab_nr, 1;
		}

		#set correct internal pointer to new current file
		PCE::Document::_set_current_nr($PCE::document{'current_nr'});
		PCE::App::TabBar::refresh_all_label();
	}
	#
	PCE::App::EditPanel::Margin::reset_line_number_width();
	PCE::App::EventList::trigger('document.list');
}


sub close_other {
	my $doc_nr = PCE::Document::_get_current_nr();
	PCE::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : PCE::Document::Change::to_number(1)
		for 0 .. PCE::Document::_get_last_nr();
}


sub close_all { close_current() for 0 .. PCE::Document::_get_last_nr() }

1;#PCE::Dialog::msg_box(undef, $file_name, '');