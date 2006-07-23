package PCE::Document::Change;
$VERSION = '0.05';

# changing the current document

use strict;

# set document with a given nr as current document
sub to_nr     { &to_number }
sub to_number {
	my $newtab = shift;
	my $oldtab = PCE::Document::_get_current_nr();

	if ($newtab != $oldtab and ref $PCE::document{'open'}[$newtab] eq 'HASH') {
		PCE::Document::Internal::save_properties($oldtab);
		PCE::File::save_current() if $PCE::config{'file'}{'save'}{'change_doc'};
		PCE::Document::Internal::change_pointer($newtab);
		PCE::App::TabBar::set_current_page($newtab);
		PCE::App::Window::refresh_title();
		PCE::Document::Internal::eval_properties($newtab);
		PCE::Edit::_center_caret();
		PCE::Document::_set_previous_nr($oldtab);
	}
}

#sub to_path{} # planing

# change to the previous used document
sub switch_back { to_number( $PCE::document{'previous_nr'} ) }

# change to the previous used document
sub tab_left {
	my $new_doc_nr = $PCE::document{'current_nr'} - 1;
	$new_doc_nr = PCE::Document::_get_last_nr() if $new_doc_nr == -1;
	to_number($new_doc_nr);
	$new_doc_nr;
}

sub tab_right {
	my $new_doc_nr = $PCE::document{'current_nr'} + 1;
	$new_doc_nr = 0 if $new_doc_nr > PCE::Document::_get_last_nr();
	to_number($new_doc_nr);
	$new_doc_nr;
}

1;
