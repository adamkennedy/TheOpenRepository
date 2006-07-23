package PCE::Edit::Bookmark;
$VERSION = '0.14';

use strict;
use Wx qw(wxSTC_MARK_SHORTARROW);


# internal subs

sub is_set{ 
	my $nr = shift;
	$PCE::internal{'search'}{'bookmark'}{$nr}{'set'};
}
# checkes if bookmark with given number is still alive an refresh his data
# or deletes data if dead
sub _refresh_data_nr {
	my $nr = shift;
	my $temp = $PCE::internal{'search'}{'bookmark'}{$nr};

	# care only about active bookmarks
	return unless $temp->{'set'};

	my $config = $PCE::config{'search'}{'bookmark'}{$nr};
	my $cur_doc_nr = PCE::Document::_get_current_nr();
	my $ep = PCE::App::EditPanel::_get();
	my $marker_byte = 1 << $nr;
	my $line;

	if ($temp->{'doc_nr'} < PCE::Document::_get_count()){
		PCE::Document::Internal::change_pointer($temp->{'doc_nr'});
		goto bookmark_found if $marker_byte & $ep->MarkerGet( $temp->{'line'} );
		if ( $config->{'file'} eq $PCE::document{'open'}[$nr]{'path'} ) {
			$line = $ep->MarkerNext(0, $marker_byte);
			if ($line > -1) {
				$temp->{'line'} = $line;
				goto bookmark_found;
			}
		}
	}

	my $doc_nr = PCE::Document::_get_nr_from_path( $config->{'file'} );
	if (ref $doc_nr eq 'ARRAY'){
		for my $doc_nr (@{$doc_nr}){
			PCE::Document::Internal::change_pointer($doc_nr);
			$line = $ep->MarkerNext(0, $marker_byte);
			if ($line > -1){
				$temp->{'doc_nr'} = $doc_nr;
				$temp->{'line'} = $line;
				goto bookmark_found;
			}
		}
	}

bookmark_disappeared:
	_delete_data($nr);
	PCE::Document::Internal::change_pointer($cur_doc_nr);
	return 0;

bookmark_found:
	# check if goto position fits in current line
	$line = $temp->{'line'};
	my $ll = $ep->LineLength( $line );
	$temp->{'col'} = $ll if $temp->{'col'} > $ll;
	$config->{'pos'} = $ep->PositionFromLine( $line ) + $temp->{'col'};
	PCE::Document::Internal::change_pointer($cur_doc_nr);
	return 1;
}

sub _delete_data {
	my $nr = shift;
	delete $PCE::config{'search'}{'bookmark'}{$nr};
	delete $PCE::internal{'search'}{'bookmark'}{$nr};
}

# API

sub define_marker {
	my $edit_panel = PCE::App::STC::_get();
	my $conf       = $PCE::config{'editpanel'}{'margin'}{'marker'};

	my $wxColor_fore = Wx::Colour->new(
		@{PCE::Config::_hex2dec_color_array( $conf->{'fore_color'} ) }
	);
	my $wxColor_back = Wx::Colour->new(
		@{PCE::Config::_hex2dec_color_array( $conf->{'back_color'} ) }
	);
	$edit_panel->MarkerDefine
		( $_, wxSTC_MARK_SHORTARROW, $wxColor_fore, $wxColor_back ) for 0 .. 9;

	#wxSTC_MARK_CIRCLE wxSTC_MARK_MINUS wxSTC_MARK_SHORTARROW wxSTC_MARK_PLUS
	#wxSTC_MARKNUM_FOLDEREND wxSTC_MARK_BOXPLUSCONNECTED
}

sub restore_all {
	my $edit_panel = PCE::App::STC::_get();
	my $cur_doc_nr = PCE::Document::_get_current_nr();
	my $bookmark   = $PCE::config{'search'}{'bookmark'};
	my $doc_nr;

	for my $nr (0..9){
		if ($bookmark->{$nr}){
			$doc_nr = PCE::Document::_get_nr_from_path( $bookmark->{$nr}{'file'} );
			if (ref $doc_nr eq 'ARRAY') { $doc_nr = $doc_nr->[0] }
			else                        { next }
			PCE::Document::Internal::change_pointer( $doc_nr );
			$edit_panel->GotoPos( $bookmark->{$nr}{'pos'} );
			toggle_nr( $nr );
		}
	}
	PCE::Document::Internal::change_pointer($cur_doc_nr);
}

sub save_all { _refresh_data_nr($_) for 0..9 }

sub toggle_nr {
	my $nr = shift;
	my $edit_panel = PCE::App::STC::_get();
	my $pos = $edit_panel->GetCurrentPos;
	my $line = $edit_panel->GetCurrentLine;
	# is selected bookmark in current line ?
	my $marker_in_line = (1 << $nr) & $edit_panel->MarkerGet($line);

	delete_nr($nr);
	unless ($marker_in_line) {
		my $temp = \%{$PCE::internal{'search'}{'bookmark'}{$nr}};
		my $config = \%{$PCE::config{'search'}{'bookmark'}{$nr}};
		$edit_panel->MarkerAdd( $line, $nr);
		$config->{'file'} = PCE::Document::_get_current_file_path();
		$config->{'pos'} = $pos;
		$temp->{'doc_nr'} = PCE::Document::_get_current_nr();
		$temp->{'col'} = $config->{'pos'} - $edit_panel->PositionFromLine($line);
		$temp->{'line'} = $line;
		$temp->{'set'} = 1;
		$edit_panel->GotoPos( $pos );
	} else { $edit_panel->GotoPos($pos) }
}

sub toggle_nr_0 { toggle_nr( 0 ) }
sub toggle_nr_1 { toggle_nr( 1 ) }
sub toggle_nr_2 { toggle_nr( 2 ) }
sub toggle_nr_3 { toggle_nr( 3 ) }
sub toggle_nr_4 { toggle_nr( 4 ) }
sub toggle_nr_5 { toggle_nr( 5 ) }
sub toggle_nr_6 { toggle_nr( 6 ) }
sub toggle_nr_7 { toggle_nr( 7 ) }
sub toggle_nr_8 { toggle_nr( 8 ) }
sub toggle_nr_9 { toggle_nr( 9 ) }

sub goto_nr {
	my $nr = shift;
	if ( _refresh_data_nr($nr) ) {
		PCE::Document::Change::to_number
			( $PCE::internal{'search'}{'bookmark'}{$nr}{'doc_nr'} );
		PCE::Edit::_goto_pos( $PCE::config{'search'}{'bookmark'}{$nr}{'pos'} );
	}
}

sub goto_nr_0 { goto_nr( 0 ) }
sub goto_nr_1 { goto_nr( 1 ) }
sub goto_nr_2 { goto_nr( 2 ) }
sub goto_nr_3 { goto_nr( 3 ) }
sub goto_nr_4 { goto_nr( 4 ) }
sub goto_nr_5 { goto_nr( 5 ) }
sub goto_nr_6 { goto_nr( 6 ) }
sub goto_nr_7 { goto_nr( 7 ) }
sub goto_nr_8 { goto_nr( 8 ) }
sub goto_nr_9 { goto_nr( 9 ) }

sub delete_all {
	PCE::Edit::_save_positions();
	delete_nr($_) for 0..9;
	PCE::Edit::_restore_positions();
	Wx::Window::SetFocus(PCE::App::STC::_get());
}

sub delete_nr {
	my $nr = shift;
	if ( _refresh_data_nr( $nr ) ){
		my $edit_panel = PCE::App::STC::_get();
		my $cur_doc_nr = PCE::Document::_get_current_nr();

		PCE::Document::Internal::change_pointer(
			$PCE::internal{'search'}{'bookmark'}{$nr}{'doc_nr'}
		);
		$edit_panel->MarkerDeleteAll($nr);
		_delete_data($nr);
		PCE::Document::Internal::change_pointer($cur_doc_nr);
	}
}

1;
