package KEPHER::Document::Internal;
$VERSION = '0.03';

use strict;
use Wx qw(wxYES wxNO);


# make document empty and reset all document properties to default
sub reset {
	my $edit_panel = KEPHER::App::STC::_get();
	KEPHER::Document::set_readonly(0);
	$edit_panel->ClearAll();
	$edit_panel->EmptyUndoBuffer();
	$edit_panel->SetSavePoint();
	KEPHER::Document::set_file_path('');
	reset_properties();
	eval_properties();
}

# restore once opened file from his settings
sub restore {
	my %file_settings = %{ shift; };
	my $file_name = $file_settings{'path'};
	if ( -e $file_name ) {

		# open only text files and empty files
		return if !-z $file_name and -B $file_name
			and ( $KEPHER::config{'file'}{'open'}{'only_text'} == 1 );
		# check if file is already open and goto this already opened
		if ( $KEPHER::config{'file'}{'open'}{'each_once'} == 1 ){
			for ( 0 .. KEPHER::Document::_get_last_nr() ) {
				return if $KEPHER::document{'open'}[$_]{'path'} eq $file_name;
			}
		}

		my $doc_nr = new_if_allowed('restore');
		load_in_current_buffer($file_name);
		%{ $KEPHER::document{'open'}[$doc_nr] } = %file_settings;
	}
}


# add newly opened file
sub add {
	my $file_name = shift;
	if ( defined $file_name and -e $file_name ) {

		# open only text files and empty files
		return if ( !-z $file_name and -B $file_name
			and $KEPHER::config{'file'}{'open'}{'only_text'} == 1 );

		# check if file is already open and goto this already opened
		if ( $KEPHER::config{'file'}{'open'}{'each_once'} == 1 ){
			for ( 0 .. KEPHER::Document::_get_last_nr() ) {
				if ( $KEPHER::document{'open'}[$_]{'path'} eq $file_name ){
					KEPHER::Document::Change::to_number($_);
					return;
				}
			}
		}
		save_properties();
		my $doc_nr = new_if_allowed('add');
		load_in_current_buffer($file_name);
		KEPHER::Document::_set_current_nr($doc_nr);
		reset_properties();
		eval_properties();
		KEPHER::App::EditPanel::Margin::autosize_line_number();
		KEPHER::App::EventList::trigger('document.list');
	}

}

# create a new document if settings allow it
sub new_if_allowed {
	my $mode = shift;	# new(empty), add(open) restore(open session)
	my $ep  = KEPHER::App::EditPanel::_get();
	my $file_name = KEPHER::Document::_get_current_file_path();
	my $old_doc_nr= KEPHER::Document::_get_current_nr();
	my $doc_nr    = $KEPHER::internal{'document'}{'buffer'};
	my $config    = $KEPHER::config{'file'}{'open'};

	# check settings
	# in single doc mode close previous doc first
	if ( $config->{'single_doc'} == 1 ) {
		KEPHER::File::close_current();
		return 0;
	}
	unless ( $mode eq 'new' ) {
		if ($ep->GetText eq '' 
		and $ep->GetModify == 0 
		and ( !$file_name or !-e $file_name ) ){
			return $old_doc_nr
				if ($config->{'into_empty_doc'} == 1)
				or ($config->{'into_only_empty_doc'} == 1
					and $KEPHER::internal{'document'}{'buffer'} == 1 );
		}
	}

	# still there? ok now we make a new document
	$KEPHER::internal{'document'}{'open'}[$doc_nr]{'pointer'}= $ep->CreateDocument;
	$KEPHER::internal{'document'}{'buffer'}++;

	change_pointer($doc_nr);
	KEPHER::App::TabBar::add_page();
	KEPHER::App::TabBar::set_current_page($doc_nr);
	return $doc_nr;
}


sub load_in_current_buffer {
	my $file_name = shift;
	$file_name ||= '';
	my $edit_panel = KEPHER::App::STC::_get();
	$edit_panel->ClearAll();
	KEPHER::File::IO::open_pipe($file_name);
	$edit_panel->EmptyUndoBuffer;
	$edit_panel->SetSavePoint;
	KEPHER::Document::set_file_path($file_name);
	$KEPHER::internal{'document'}{'loaded'}++;
}


sub check_b4_overwite {
	my $filename = shift;
	$filename = KEPHER::Document::_get_current_file_path() unless $filename;
	my $allow = $KEPHER::config{'file'}{'save'}{'overwrite'};
	if ( -e $filename ) {
		my $frame = &KEPHER::App::Window::_get();
		my $label = \%{ $KEPHER::localisation{'dialog'} };
		if ( $allow eq 'ask' ) {
			my $answer = KEPHER::Dialog::get_confirm_2( $frame,
				"$label->{general}{overwrite} $filename ?",
				$label->{'file'}{'overwrite'},
				-1, -1
			);
			return 1 if $answer == wxYES;
			return 0 if $answer == wxNO;
		} else {
			KEPHER::Dialog::info_box( $frame,
				$label->{'general'}{'dont_allow'},
				$label->{'file'}{'overwrite'}
			) unless $allow;
			return $allow;
		}
	} else { return -1 }
}

# set the config default to the selected document
sub reset_properties {
	my $doc_nr = shift;
	$doc_nr = $KEPHER::document{'current_nr'} unless $doc_nr;
	my $defaults  = \%{ $KEPHER::config{'file'}{'defaultsettings'} };
	my $doc_attr  = \%{ $KEPHER::document{'open'}[$doc_nr] };
	my $file_name = $doc_attr->{'path'};

	$doc_attr->{'syntaxmode'} = $defaults->{'syntaxmode'} eq 'auto'
		? KEPHER::Document::SyntaxMode::_get_auto($doc_nr)
		: $defaults->{'syntaxmode'};

	if ($file_name and ( -e $file_name )) 
		 {$doc_attr->{'EOL'} = $defaults->{'EOL_open'}}
	else {$doc_attr->{'EOL'} = $defaults->{'EOL_new'};
		KEPHER::Document::set_EOL_mode( $doc_attr->{'EOL'} );
	}
	$doc_attr->{'tab_use'}  = $defaults->{'tab_use'};
	$doc_attr->{'tab_size'} = $defaults->{'tab_size'};
	$doc_attr->{'codepage'} = $defaults->{'codepage'};
	$doc_attr->{'readonly'} = $defaults->{'readonly'};
	$doc_attr->{'cursor_pos'} = 
		$defaults->{'cursor_pos'} ? $defaults->{'cursor_pos'} : 0;
	$doc_attr->{'edit_pos'} = -1;
}


sub eval_properties {
	my $doc_nr = shift;
	$doc_nr = KEPHER::Document::_get_current_nr() if ( !$doc_nr );
	my $doc_attr = \%{$KEPHER::document{'open'}[$doc_nr]};
	my $doc_data = \%{$KEPHER::internal{'document'}{'open'}[$doc_nr]};
	my $ep = KEPHER::App::EditPanel::_get();

	$doc_attr->{'syntaxmode'} = "none" unless $doc_attr->{'syntaxmode'};
	KEPHER::Document::SyntaxMode::change_to( $doc_attr->{'syntaxmode'} );
	KEPHER::Document::set_EOL_mode( $doc_attr->{'EOL'} );
	KEPHER::Document::set_tab_mode( $doc_attr->{'tab_use'} );
	KEPHER::Document::set_tab_size( $doc_attr->{'tab_size'} );
	KEPHER::Document::set_readonly( $doc_attr->{'readonly'} );

	# setting selection and caret position
	if ($doc_data->{'selstart'} and $doc_data->{'selstart'}) {
		$doc_attr->{'cursor_pos'} < $doc_data->{'selend'}
			? $ep->SetSelection( $doc_data->{'selend'},$doc_data->{'selstart'})
			: $ep->SetSelection( $doc_data->{'selstart'},$doc_data->{'selend'});
	} else { $ep->GotoPos( $doc_attr->{'cursor_pos'} ) }
	if ($KEPHER::config{'file'}{'open'}{'in_current_dir'}){
		$KEPHER::config{'file'}{'current'}{'directory'} = $doc_data->{'directory'}
			if $doc_data->{'directory'};
	} else { $KEPHER::config{'file'}{'current'}{'directory'} = '' }
	KEPHER::Edit::_let_caret_visible();
	KEPHER::App::StatusBar::refresh();
	KEPHER::App::EditPanel::paint_bracelight()
		if $KEPHER::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'};
	Wx::Window::SetFocus($ep) unless $KEPHER::internal{'dialog'}{'control'};
	
	KEPHER::App::EventList::trigger
		('document.text.select','document.text.change','document.savepoint');
}


sub save_properties {
	my $doc_nr = shift;
	$doc_nr = $KEPHER::document{'current_nr'} unless $doc_nr;
	my $doc_attr = $KEPHER::document{'open'}[$doc_nr];
	my $doc_data = $KEPHER::internal{'document'}{'open'}[$doc_nr];
	my $ep = KEPHER::App::STC::_get();

	$doc_attr->{'cursor_pos'}= $ep->GetCurrentPos;
	$doc_data->{'selstart'} = $ep->GetSelectionStart;
	$doc_data->{'selend'}   = $ep->GetSelectionEnd;
	$doc_data->{'modified'} = $ep->GetModify;
	$doc_data->{'empty'}    = $ep->GetTextLength ? 0 : 1;
}


sub change_pointer {
	my $newtab = shift;
	$newtab = 0 unless $newtab ;
	my $oldtab  = KEPHER::Document::_get_current_nr();
	my $docsdata = $KEPHER::internal{'document'}{'open'};
	my $ep      = KEPHER::App::EditPanel::_get();
	$ep->AddRefDocument( $docsdata->[$oldtab]{'pointer'} );
	$ep->SetDocPointer( $docsdata->[$newtab]{'pointer'} );
	$ep->ReleaseDocument( $docsdata->[$newtab]{'pointer'} );
	KEPHER::Document::_set_current_nr($newtab);
}

# various helper
sub dissect_path {
	my ( $file_path, $doc_nr ) = @_;
	my ( @dirs, @filenameparts, $dir, $name, $ending );
	$file_path = '' unless $file_path;
	$doc_nr = KEPHER::Document::_get_current_nr() unless $doc_nr;

	# split filename into parts
	if ( length($file_path) > 0 ) {
		$file_path = set_path_slashes_to_OS_standart($file_path);
		@dirs = split( /\\/, $file_path ) if $file_path =~ /\\/;
		@dirs = split( /\//, $file_path ) if $file_path =~ /\//;
		$dir .= $dirs[$_].'/' for 0 .. $#dirs - 1;
		$name = $#dirs > -1 ? $dirs[-1] : $file_path;
		@filenameparts = split( /\./, $name );
		$ending = $filenameparts[-1];
	}
	my $doc_data = $KEPHER::internal{'document'}{'open'}[$doc_nr];
	$doc_data->{'directory'} = $dir;
	$doc_data->{'name'}      = $name;
	$doc_data->{'ending'}    = $ending;
}

sub set_path_slashes_to_OS_standart{
	my $path = shift;
	if  ($^O eq 'MSWin32') {$path =~ s./.\\.g}
	else				   {$path =~ s.\\./.g}
	return $path;
}

sub standartize_path_slashes {
	my $path = shift;
	$path =~ s.\\./.g;
	return $path;
}

1;
