package Kepher::File;
$VERSION = '0.34';

# file save events, drag n drop files, file menu calls

use strict;
use Wx qw(wxYES wxNO wxCANCEL);

#
# event handling
#
sub savepoint_left {
	$Kepher::internal{'document'}{'modified'}++
		unless $Kepher::internal{'current_doc'}{'modified'};
	$Kepher::internal{'current_doc'}{'modified'} = 1;
	Kepher::App::TabBar::refresh_current_label()
		if $Kepher::config{'app'}{'tabbar'}{'info_symbol'};
	Kepher::App::EventList::trigger('document.savepoint');
}
sub savepoint_reached {
	$Kepher::internal{'document'}{'modified'}-- if 
		$Kepher::internal{'current_doc'}{'modified'};
	$Kepher::internal{'current_doc'}{'modified'} = 0;
	Kepher::App::TabBar::refresh_current_label();
	Kepher::App::EventList::trigger('document.savepoint');
}

sub can_save     { $Kepher::internal{'current_doc'}{'modified'} }
sub can_save_all { $Kepher::internal{'document'}{'modified'} }

#
# add file per drag and drop
#
sub add_dropped {
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : Kepher::Document::Internal::add($_) for $event->GetFiles;
}

# add dir per drag and drop
sub add_dir{
	my $dir = shift;
	opendir (DIR, $dir);
	my @dir_items = readdir(DIR);
	closedir(DIR);
	my $path;
	my $recursive = $Kepher::config{'file'}{'open'}{'dir_recursive'};

	foreach (@dir_items) {
		$path = "$dir/$_";
		if (-d $path) {
			next if not $recursive or $_ eq '.' or $_ eq '..';
			add_dir($path);
		} else { Kepher::Document::Internal::add($path) }
	}
}

#
# file menu calls
#
sub new {
	Kepher::Document::Internal::new_if_allowed('new');
	Kepher::Document::Internal::reset();
}


sub open {
	# buttons dont freeze while computing
	Kepher::App::get_ref->Yield();

	# file selector dialog
	my $files = Kepher::Dialog::get_files_open( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'open'},
		$Kepher::config{'file'}{'current'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'all'}
	);

	# opening selected files
	if (ref $files eq 'ARRAY') { Kepher::Document::Internal::add($_) for @$files }
}


sub reload_current {
	my $file_path = Kepher::Document::_get_current_file_path();
	my $nr = Kepher::Document::_get_current_nr();
	if ($file_path and -e $file_path){
		my $ep = Kepher::App::EditPanel::_get();
		Kepher::Document::Internal::save_properties();
		$ep->BeginUndoAction;
		$ep->SetText("");
		Kepher::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		Kepher::Document::Internal::eval_properties();
		Kepher::App::EditPanel::Margin::autosize_line_number()
			if ($Kepher::config{'editpanel'}{'margin'}{'linenumber'}{'autosize'}
			and $Kepher::config{'editpanel'}{'margin'}{'linenumber'}{'width'} );
	} else {}
}


sub reload_all {
	my $doc_nr = Kepher::Document::_get_current_file_path();
	for ( 0 .. Kepher::Document::_get_last_nr() ) {
		Kepher::Document::Change::to_number($_);
		reload_current();
	}
	Kepher::Document::Change::to_number($doc_nr);
}


sub insert {
	my $insertfilename = Kepher::Dialog::get_file_open( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'insert'},
		$Kepher::config{'file'}{'current'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'all'}
	);
	if ( -e $insertfilename ) {
		my $ep = Kepher::App::EditPanel::_get();
		my $text = Kepher::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = Kepher::App::EditPanel::_get();
	my $file_name   = Kepher::Document::_get_current_file_path();
	my $save_config = $Kepher::config{'file'}{'save'};
	if ( $ep->GetModify == 1 or $save_config->{'unchanged'} ) {
		if ( $file_name and length($file_name) > 0 ) {
			if ( -e $file_name and not -w $file_name ) {
				my $err_msg = $Kepher::localisation{'dialog'}{'error'};
				Kepher::Dialog::warning_box( Kepher::App::Window::_get(),
					$err_msg->{write_protected}.'\n'.$err_msg->{write_protected2},
					$err_msg->{'file'} );
				save_as();
			} else {
				rename $file_name, $file_name . '~'
					if $Kepher::config{'file'}{'save'}{'tilde_backup'} == 1;
				Kepher::File::IO::write_buffer( $file_name, $ep->GetText );
				Kepher::Config::Global::reload_config_file($file_name)
					if $save_config->{'reload_config'} == 1;
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $filename = Kepher::Dialog::get_file_save( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'save_as'},
		$Kepher::config{'file'}{'current'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'all'}
	);
	if (length($filename) > 0
		and Kepher::Document::Internal::check_b4_overwite($filename) ) {
		my $ep = Kepher::App::EditPanel::_get();
		$Kepher::internal{'document'}{'loaded'}++
			if length($Kepher::document{'current'}{'path'}) == 0;
		Kepher::File::IO::write_buffer( $filename, $ep->GetText );
		Kepher::Document::Internal::save_properties();
		Kepher::Document::set_file_path($filename);
		Kepher::Document::SyntaxMode::change_to('auto');
		$Kepher::config{'file'}{'current'}{'directory'} = 
			$Kepher::internal{'current_doc'}{'directory'};
		$ep->SetSavePoint;
		Kepher::App::EventList::trigger('document.list');
	}
}


sub save_copy_as {
	my $file_name = Kepher::Dialog::get_file_save( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'save_copy_as'},
		$Kepher::config{'file'}{'current'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'all'} );
	Kepher::File::IO::write_buffer( $file_name, Kepher::App::EditPanel::_get()->GetText )
		if $file_name and Kepher::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = Kepher::Dialog::get_file_save( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'rename'},
		$Kepher::config{'file'}{'current'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'all'} );
	if ($new_path_name){
		my $old_path_name = Kepher::Document::_get_current_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		Kepher::Document::set_file_path($new_path_name);
	}
}


sub save_all {
	my $doc_nr = Kepher::Document::_get_current_nr();
	my $doc_data = $Kepher::internal{'document'}{'open'};
	Kepher::Document::Internal::save_properties();
	for ( 0 .. &Kepher::Document::_get_last_nr ) {
		if ($doc_data->[$_]{'modified'}){
			Kepher::Document::Internal::change_pointer($_);
			save_current();
		}
	}
	Kepher::Document::Internal::change_pointer($doc_nr);
	Kepher::Document::Internal::eval_properties($doc_nr);
}


sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = Kepher::App::EditPanel::_get();
	my $close_tab_nr = Kepher::Document::_get_current_nr();
	my $config       = $Kepher::config{'file'}{'save'};
	my $save_answer  = wxNO;

	# save text if options allow it
	if ($ep->GetModify == 1 or $config->{'unchanged'} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{'empty'} eq 1) {
			if ($config->{'b4_close'} eq 'ask' or $config->{'b4_close'} eq '2'){
				my $l10n = $Kepher::localisation{'dialog'}{'file'};
				$save_answer = Kepher::Dialog::get_confirm_3( Kepher::App::Window::_get(),
					$l10n->{'save_current'}, $l10n->{'close_unsaved'} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{'b4_close'} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

	# empty last document
	if ( $Kepher::internal{'document'}{'buffer'} == 1 ) {
		$Kepher::internal{'file'}{'current'}{'loaded'} = 0;
		Kepher::Document::Internal::reset();
	}

	# close document
	elsif ( $Kepher::internal{'document'}{'buffer'} > 1 ) {
		# select to which file nr to jump
		my $new_tab_nr = $close_tab_nr + 1;
		if ( defined $Kepher::document{'open'}[$new_tab_nr] ) {
			Kepher::Document::Change::to_number($new_tab_nr);
			$Kepher::document{'current_nr'}--;
		} else {
			$new_tab_nr -= 2;
			Kepher::Document::Change::to_number($new_tab_nr);
		}
		$Kepher::internal{'document'}{'buffer'}--;
		$Kepher::internal{'document'}{'loaded'}--
			if ( $Kepher::document{'open'}[$close_tab_nr]{'path'} );
		Kepher::App::TabBar::delete_page($close_tab_nr);

		# release file data of closed file
		if (ref $Kepher::document{'open'} eq 'ARRAY' ) {
			splice @{$Kepher::document{'open'}}, $close_tab_nr, 1;
			splice @{$Kepher::internal{'document'}{'open'}}, $close_tab_nr, 1;
		}

		#set correct internal pointer to new current file
		Kepher::Document::_set_current_nr($Kepher::document{'current_nr'});
		Kepher::App::TabBar::refresh_all_label();
	}
	#
	Kepher::App::EditPanel::Margin::reset_line_number_width();
	Kepher::App::EventList::trigger('document.list');
}


sub close_other {
	my $doc_nr = Kepher::Document::_get_current_nr();
	Kepher::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : Kepher::Document::Change::to_number(1)
		for 0 .. Kepher::Document::_get_last_nr();
}


sub close_all { close_current() for 0 .. Kepher::Document::_get_last_nr() }

1;#Kepher::Dialog::msg_box(undef, $file_name, '');