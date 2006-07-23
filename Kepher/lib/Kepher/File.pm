package KEPHER::File;
$VERSION = '0.34';

# file save events, drag n drop files, file menu calls

use strict;
use Wx qw(wxYES wxNO wxCANCEL);

#
# event handling
#
sub savepoint_left {
	$KEPHER::internal{'document'}{'modified'}++
		unless $KEPHER::internal{'current_doc'}{'modified'};
	$KEPHER::internal{'current_doc'}{'modified'} = 1;
	KEPHER::App::TabBar::refresh_current_label()
		if $KEPHER::config{'app'}{'tabbar'}{'info_symbol'};
	KEPHER::App::EventList::trigger('document.savepoint');
}
sub savepoint_reached {
	$KEPHER::internal{'document'}{'modified'}-- if 
		$KEPHER::internal{'current_doc'}{'modified'};
	$KEPHER::internal{'current_doc'}{'modified'} = 0;
	KEPHER::App::TabBar::refresh_current_label();
	KEPHER::App::EventList::trigger('document.savepoint');
}

sub can_save     { $KEPHER::internal{'current_doc'}{'modified'} }
sub can_save_all { $KEPHER::internal{'document'}{'modified'} }

#
# add file per drag and drop
#
sub add_dropped {
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : KEPHER::Document::Internal::add($_) for $event->GetFiles;
}

# add dir per drag and drop
sub add_dir{
	my $dir = shift;
	opendir (DIR, $dir);
	my @dir_items = readdir(DIR);
	closedir(DIR);
	my $path;
	my $recursive = $KEPHER::config{'file'}{'open'}{'dir_recursive'};

	foreach (@dir_items) {
		$path = "$dir/$_";
		if (-d $path) {
			next if not $recursive or $_ eq '.' or $_ eq '..';
			add_dir($path);
		} else { KEPHER::Document::Internal::add($path) }
	}
}

#
# file menu calls
#
sub new {
	KEPHER::Document::Internal::new_if_allowed('new');
	KEPHER::Document::Internal::reset();
}


sub open {
	# buttons dont freeze while computing
	KEPHER::App::get_ref->Yield();

	# file selector dialog
	my $files = KEPHER::Dialog::get_files_open( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'open'},
		$KEPHER::config{'file'}{'current'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'all'}
	);

	# opening selected files
	if (ref $files eq 'ARRAY') { KEPHER::Document::Internal::add($_) for @$files }
}


sub reload_current {
	my $file_path = KEPHER::Document::_get_current_file_path();
	my $nr = KEPHER::Document::_get_current_nr();
	if ($file_path and -e $file_path){
		my $ep = KEPHER::App::STC::_get();
		KEPHER::Document::Internal::save_properties();
		$ep->BeginUndoAction;
		$ep->SetText("");
		KEPHER::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		KEPHER::Document::Internal::eval_properties();
		KEPHER::App::EditPanel::Margin::autosize_line_number()
			if ($KEPHER::config{'editpanel'}{'margin'}{'linenumber'}{'autosize'}
			and $KEPHER::config{'editpanel'}{'margin'}{'linenumber'}{'width'} );
	} else {}
}


sub reload_all {
	my $doc_nr = KEPHER::Document::_get_current_file_path();
	for ( 0 .. KEPHER::Document::_get_last_nr() ) {
		KEPHER::Document::Change::to_number($_);
		reload_current();
	}
	KEPHER::Document::Change::to_number($doc_nr);
}


sub insert {
	my $insertfilename = KEPHER::Dialog::get_file_open( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'insert'},
		$KEPHER::config{'file'}{'current'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'all'}
	);
	if ( -e $insertfilename ) {
		my $ep = KEPHER::App::STC::_get();
		my $text = KEPHER::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = KEPHER::App::STC::_get();
	my $file_name   = KEPHER::Document::_get_current_file_path();
	my $save_config = $KEPHER::config{'file'}{'save'};
	if ( $ep->GetModify == 1 or $save_config->{'unchanged'} ) {
		if ( $file_name and length($file_name) > 0 ) {
			if ( -e $file_name and not -w $file_name ) {
				my $err_msg = $KEPHER::localisation{'dialog'}{'error'};
				KEPHER::Dialog::warning_box( KEPHER::App::Window::_get(),
					$err_msg->{write_protected}.'\n'.$err_msg->{write_protected2},
					$err_msg->{'file'} );
				save_as();
			} else {
				rename $file_name, $file_name . '~'
					if $KEPHER::config{'file'}{'save'}{'tilde_backup'} == 1;
				KEPHER::File::IO::write_buffer( $file_name, $ep->GetText );
				KEPHER::Config::Global::reload_config_file($file_name)
					if $save_config->{'reload_config'} == 1;
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $filename = KEPHER::Dialog::get_file_save( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'save_as'},
		$KEPHER::config{'file'}{'current'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'all'}
	);
	if (length($filename) > 0
		and KEPHER::Document::Internal::check_b4_overwite($filename) ) {
		my $ep = KEPHER::App::STC::_get();
		$KEPHER::internal{'document'}{'loaded'}++
			if length($KEPHER::document{'current'}{'path'}) == 0;
		KEPHER::File::IO::write_buffer( $filename, $ep->GetText );
		KEPHER::Document::Internal::save_properties();
		KEPHER::Document::set_file_path($filename);
		KEPHER::Document::SyntaxMode::change_to('auto');
		$KEPHER::config{'file'}{'current'}{'directory'} = 
			$KEPHER::internal{'current_doc'}{'directory'};
		$ep->SetSavePoint;
		KEPHER::App::EventList::trigger('document.list');
	}
}


sub save_copy_as {
	my $file_name = KEPHER::Dialog::get_file_save( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'save_copy_as'},
		$KEPHER::config{'file'}{'current'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'all'} );
	KEPHER::File::IO::write_buffer( $file_name, KEPHER::App::STC::_get()->GetText )
		if $file_name and KEPHER::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = KEPHER::Dialog::get_file_save( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'rename'},
		$KEPHER::config{'file'}{'current'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'all'} );
	if ($new_path_name){
		my $old_path_name = KEPHER::Document::_get_current_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		KEPHER::Document::set_file_path($new_path_name);
	}
}


sub save_all {
	my $doc_nr = KEPHER::Document::_get_current_nr();
	my $doc_data = $KEPHER::internal{'document'}{'open'};
	KEPHER::Document::Internal::save_properties();
	for ( 0 .. &KEPHER::Document::_get_last_nr ) {
		if ($doc_data->[$_]{'modified'}){
			KEPHER::Document::Internal::change_pointer($_);
			save_current();
		}
	}
	KEPHER::Document::Internal::change_pointer($doc_nr);
	KEPHER::Document::Internal::eval_properties($doc_nr);
}


sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = KEPHER::App::STC::_get();
	my $close_tab_nr = KEPHER::Document::_get_current_nr();
	my $config       = $KEPHER::config{'file'}{'save'};
	my $save_answer  = wxNO;

	# save text if options allow it
	if ($ep->GetModify == 1 or $config->{'unchanged'} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{'empty'} eq 1) {
			if ($config->{'b4_close'} eq 'ask' or $config->{'b4_close'} eq '2'){
				my $l10n = $KEPHER::localisation{'dialog'}{'file'};
				$save_answer = KEPHER::Dialog::get_confirm_3( KEPHER::App::Window::_get(),
					$l10n->{'save_current'}, $l10n->{'close_unsaved'} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{'b4_close'} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

	# empty last document
	if ( $KEPHER::internal{'document'}{'buffer'} == 1 ) {
		$KEPHER::internal{'file'}{'current'}{'loaded'} = 0;
		KEPHER::Document::Internal::reset();
	}

	# close document
	elsif ( $KEPHER::internal{'document'}{'buffer'} > 1 ) {
		# select to which file nr to jump
		my $new_tab_nr = $close_tab_nr + 1;
		if ( defined $KEPHER::document{'open'}[$new_tab_nr] ) {
			KEPHER::Document::Change::to_number($new_tab_nr);
			$KEPHER::document{'current_nr'}--;
		} else {
			$new_tab_nr -= 2;
			KEPHER::Document::Change::to_number($new_tab_nr);
		}
		$KEPHER::internal{'document'}{'buffer'}--;
		$KEPHER::internal{'document'}{'loaded'}--
			if ( $KEPHER::document{'open'}[$close_tab_nr]{'path'} );
		KEPHER::App::TabBar::delete_page($close_tab_nr);

		# release file data of closed file
		if (ref $KEPHER::document{'open'} eq 'ARRAY' ) {
			splice @{$KEPHER::document{'open'}}, $close_tab_nr, 1;
			splice @{$KEPHER::internal{'document'}{'open'}}, $close_tab_nr, 1;
		}

		#set correct internal pointer to new current file
		KEPHER::Document::_set_current_nr($KEPHER::document{'current_nr'});
		KEPHER::App::TabBar::refresh_all_label();
	}
	#
	KEPHER::App::EditPanel::Margin::reset_line_number_width();
	KEPHER::App::EventList::trigger('document.list');
}


sub close_other {
	my $doc_nr = KEPHER::Document::_get_current_nr();
	KEPHER::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : KEPHER::Document::Change::to_number(1)
		for 0 .. KEPHER::Document::_get_last_nr();
}


sub close_all { close_current() for 0 .. KEPHER::Document::_get_last_nr() }

1;#KEPHER::Dialog::msg_box(undef, $file_name, '');