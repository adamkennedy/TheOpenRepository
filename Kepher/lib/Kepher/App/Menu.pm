package KEPHER::App::Menu;
$VERSION = '0.10';

use strict;
use constant CFGROOT => 'menu'; # name of root node in configs
use constant APPROOT => 'menu'; #
use Wx qw (wxITEM_NORMAL wxITEM_CHECK wxITEM_RADIO wxBITMAP_TYPE_XPM);
use Wx::Event qw (EVT_MENU EVT_MENU_OPEN EVT_MENU_HIGHLIGHT EVT_SET_FOCUS);

sub set { $KEPHER::app{(APPROOT)}{$_[0]}{ref} = $_[1] if ref $_[1] eq 'Wx::Menu' }
sub get { $KEPHER::app{(APPROOT)}{$_[0]}{ref}
	if ref $KEPHER::app{(APPROOT)}{$_[0]}{ref} eq 'Wx::Menu'
}

# ready menu for display
sub ready {
	my $id = shift;
	if (ref $KEPHER::app{(APPROOT)}{$id} eq 'HASH'){
		my $menu = \%{$KEPHER::app{(APPROOT)}{$id}};

		if ($menu->{absolete} and $menu->{update})
			{ $menu->{absolete} = 0 if $menu->{update}() }

		if (ref $menu->{onopen} eq 'HASH')
			{ $_->() for values %{$menu->{onopen}} }

		get($id);
	}
}
sub set_absolete{ $KEPHER::app{(APPROOT)}{$_[0]}{absolete} = 1 }
sub not_absolete{ $KEPHER::app{(APPROOT)}{$_[0]}{absolete} = 0 }
sub is_absolete { $KEPHER::app{(APPROOT)}{$_[0]}{absolete} }
sub set_update {
	$KEPHER::app{(CFGROOT)}{$_[0]}{update} = $_[1] if ref $_[1] eq 'CODE'
}
sub no_update  {
	delete $KEPHER::app{(APPROOT)}{$_[0]}{update} 
		if exists $KEPHER::app{(APPROOT)}{$_[0]}
}

sub add_onopen_check{
	return until ref $_[2] eq 'CODE';
	$KEPHER::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] } = $_[2];
}
sub del_onopen_check{
	return until $_[1];
	delete $KEPHER::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] }
		if exists $KEPHER::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] };
}

# 
sub create_dynamic {
	my $menu_id = shift;
	my $menu_name = shift;

	if ($menu_name eq '&file_history'){
		set_update($menu_id, sub {
			my @menu_data;
		});
	} elsif ($menu_name eq '&document_list'){
		set_update($menu_id, sub {
			return unless exists $KEPHER::internal{document}{buffer};
			my @menu_data;
			my @names = @{&KEPHER::Document::_get_all_names};
			my @pathes = @{&KEPHER::Document::_get_all_pathes};
			my $space = ' ';
			#$menu_data[0]{type} = 'item'; document-change-prev-tab
			#$menu_data[1]{type} = 'item'; document-change-next-tab
			#$menu_data[2]{type} = 'item'; document-change-back
			#$menu_data[3]{type} = '';
			for my $nr (0 .. KEPHER::Document::_get_last_nr()){
				my $item = \%{$menu_data[$nr]};
				$space = '' if $nr == 9;
				$item->{type} = 'radioitem';
				$item->{label}= $space.($nr+1)." - $names[$nr] \t - $pathes[$nr]";
				$item->{help} = '';
				$item->{call} = eval 'sub {KEPHER::Document::Change::to_nr('.$nr.')}';
				$item->{state}= 1;
			}
			eval_data($menu_id, \@menu_data);
		});
		KEPHER::App::EventList::add_call (
			'document.list', 'document_list_menu',
			sub{ set_absolete('document_list') }
		);

		add_onopen_check( $menu_id, 'select', sub {
			my $menu = get($menu_id);
			$menu->Check (
				$menu->FindItemByPosition(0)->GetId + 
				KEPHER::Document::_get_current_nr(), 1
			);
		});
	}
	set($menu_id, eval_data());
	set_absolete($menu_id);
}

sub create_static{
	my $menu_id = shift;
	my $menu_def = shift;

	return unless ref $menu_def eq 'ARRAY';
	not_absolete($menu_id);
	eval_data($menu_id, assemble_data_from_def($menu_def));
}

# make menu data structures (MDS) from menu skeleton definitions
sub assemble_data_from_def {
	my $menu_def = shift;
	return unless ref $menu_def eq 'ARRAY';

	my @mds = (); # menu data structure
	my ($cmd_name, $cmd_data, $type_name, $pos, $sub_id);
	for my $item_def (@$menu_def){
		# sorting commented lines out
		next if substr($item_def, -1) eq '#';
		my %item;
		# recursive call for submenus
		if (ref $item_def eq 'HASH'){
			$sub_id = $_ for keys %$item_def;
			$item{type} = 'menu';
			$item{id} = $sub_id;
			$item{label} = $KEPHER::localisation{'app'}{'menu'}{$sub_id};
			$item{data} = assemble_data_from_def($item_def->{$sub_id}); 
		# creating data
		} elsif ($item_def eq '' or $item_def eq 'separator'){
			$item{type} = ''
		} else {
			$pos = index $item_def, ' ';
			next if $pos == -1;
			$item{type} = substr $item_def, 0, $pos;
			$cmd_name = substr $item_def, $pos+1;
			$cmd_data = KEPHER::App::CommandList::get_cmd_properties( $cmd_name );
			# skipping when command call is missing
			next unless ref $cmd_data and exists $cmd_data->{call};
			for ('call','enable','state','label','help','icon'){
				$item{$_} = $cmd_data->{$_} if $cmd_data->{$_}
			}
		}
		push @mds, \%item;
	}
	return \@mds;
}


# eval menu data structures (MDS) to wxMenus
sub eval_data {
	my $menu_id = shift;
	my $menu_data = shift;
	my $menu = Wx::Menu->new();
	return $menu unless ref $menu_data eq 'ARRAY';
	my $win = KEPHER::App::Window::_get();

	my ($item_id, $kind);
	$item_id = exists $KEPHER::app{(APPROOT)}{$menu_id}{item_id}
		? $KEPHER::app{(APPROOT)}{$menu_id}{item_id}
		: $KEPHER::app{GUI}{masterID}++ * 100;
	$KEPHER::app{(APPROOT)}{$menu_id}{item_id} = $item_id;

	for my $item_data (@$menu_data){
		if (not $item_data->{type} or $item_data->{type} eq 'separator'){
			$menu->AppendSeparator;
			next;
		}
		if ($item_data->{type} eq 'menu'){
			next unless ref $item_data->{data} eq 'ARRAY';
			$menu->Append( $item_id++, $item_data->{label}, 
				eval_data( $item_data->{id}, $item_data->{data} ));
			next;
		}
		if ($item_data->{type} eq 'checkitem'){
			$kind = $item_data->{state} ? wxITEM_CHECK : wxITEM_NORMAL
		} elsif ($item_data->{type} eq 'radioitem'){
			$kind = $item_data->{state} ? wxITEM_RADIO : wxITEM_NORMAL
		} elsif ($item_data->{type} eq 'item'){
			$kind = wxITEM_NORMAL 
		} else { next }

		my $menu_item = Wx::MenuItem->new
			($menu, $item_id, $item_data->{label}, '', $kind);
		$menu_item->SetBitmap( $item_data->{icon} ) 
			if ref $item_data->{icon} eq 'Wx::Bitmap';
		
		add_onopen_check( $menu_id, 'enable '.$item_id, sub {
			$menu_item->Enable( $item_data->{enable}() );
		} ) if ref $item_data->{enable} eq 'CODE';
		add_onopen_check( $menu_id, 'check '.$item_id, sub {
			$menu_item->Check( $item_data->{state}() )
		} ) if ref $item_data->{state} eq 'CODE';

		EVT_MENU          ($win, $item_id, $item_data->{call} );
		EVT_MENU_HIGHLIGHT($win, $item_id, sub {
			KEPHER::App::StatusBar::info_msg( $item_data->{help} )
		});
		$menu->Append( $menu_item );
		$item_id++; 
	}

	KEPHER::App::EventList::add_call('menu.open', $menu, sub {ready($menu_id)} );
	set($menu_id, $menu);
	return $menu;
}

1;