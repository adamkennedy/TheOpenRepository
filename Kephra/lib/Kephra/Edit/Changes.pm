package Kephra::Edit::Changes;
$VERSION = '0.01';

# undo, redo etc.

sub _get_panel { Kephra::App::EditPanel::_get() }

sub undo { _get_panel()->Undo }
sub redo { _get_panel()->Redo }

sub undo_several {
	my $ep = _get_panel();
	$ep->Undo for 1 .. $Kephra::config{'editpanel'}{'history'}{'fast_undo_steps'};
}

sub redo_several {
	my $ep = _get_panel();
	$ep->Redo for 1 .. $Kephra::config{'editpanel'}{'history'}{'fast_undo_steps'};
}

sub undo_begin {
	my $ep = _get_panel();
	$ep->Undo while $ep->CanUndo;
}

sub redo_end {
	my $ep = _get_panel();
	$ep->Redo while $ep->CanRedo;
}

sub clear_history { 
	_get_panel()->EmptyUndoBuffer;
	Kephra::App::EventList::trigger('document.savepoint');
}

sub can_undo  { _get_panel()->CanUndo }
sub can_redo  { _get_panel()->CanRedo }

1;