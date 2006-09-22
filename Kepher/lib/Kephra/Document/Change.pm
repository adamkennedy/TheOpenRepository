package Kepher::Document::Change;
$VERSION = '0.05';

# changing the current document

use strict;

# set document with a given nr as current document
sub to_nr     { &to_number }
sub to_number {
	my $newtab = shift;
	my $oldtab = Kepher::Document::_get_current_nr();

	if ($newtab != $oldtab and ref $Kepher::document{'open'}[$newtab] eq 'HASH') {
		Kepher::Document::Internal::save_properties($oldtab);
		Kepher::File::save_current() if $Kepher::config{'file'}{'save'}{'change_doc'};
		Kepher::Document::Internal::change_pointer($newtab);
		Kepher::App::TabBar::set_current_page($newtab);
		Kepher::App::Window::refresh_title();
		Kepher::Document::Internal::eval_properties($newtab);
		Kepher::Edit::_center_caret();
		Kepher::Document::_set_previous_nr($oldtab);
	}
}

#sub to_path{} # planing

# change to the previous used document
sub switch_back { to_number( $Kepher::document{'previous_nr'} ) }

# change to the previous used document
sub tab_left {
	my $new_doc_nr = $Kepher::document{'current_nr'} - 1;
	$new_doc_nr = Kepher::Document::_get_last_nr() if $new_doc_nr == -1;
	to_number($new_doc_nr);
	$new_doc_nr;
}

sub tab_right {
	my $new_doc_nr = $Kepher::document{'current_nr'} + 1;
	$new_doc_nr = 0 if $new_doc_nr > Kepher::Document::_get_last_nr();
	to_number($new_doc_nr);
	$new_doc_nr;
}

1;
