package KEPHER::Document::Change;
$VERSION = '0.05';

# changing the current document

use strict;

# set document with a given nr as current document
sub to_nr     { &to_number }
sub to_number {
	my $newtab = shift;
	my $oldtab = KEPHER::Document::_get_current_nr();

	if ($newtab != $oldtab and ref $KEPHER::document{'open'}[$newtab] eq 'HASH') {
		KEPHER::Document::Internal::save_properties($oldtab);
		KEPHER::File::save_current() if $KEPHER::config{'file'}{'save'}{'change_doc'};
		KEPHER::Document::Internal::change_pointer($newtab);
		KEPHER::App::TabBar::set_current_page($newtab);
		KEPHER::App::Window::refresh_title();
		KEPHER::Document::Internal::eval_properties($newtab);
		KEPHER::Edit::_center_caret();
		KEPHER::Document::_set_previous_nr($oldtab);
	}
}

#sub to_path{} # planing

# change to the previous used document
sub switch_back { to_number( $KEPHER::document{'previous_nr'} ) }

# change to the previous used document
sub tab_left {
	my $new_doc_nr = $KEPHER::document{'current_nr'} - 1;
	$new_doc_nr = KEPHER::Document::_get_last_nr() if $new_doc_nr == -1;
	to_number($new_doc_nr);
	$new_doc_nr;
}

sub tab_right {
	my $new_doc_nr = $KEPHER::document{'current_nr'} + 1;
	$new_doc_nr = 0 if $new_doc_nr > KEPHER::Document::_get_last_nr();
	to_number($new_doc_nr);
	$new_doc_nr;
}

1;
