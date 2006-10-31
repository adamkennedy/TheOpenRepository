package Kephra::App::Menu;
$VERSION = '0.10';

use strict;
use constant CFGROOT => 'menu'; # name of root node in configs
use constant APPROOT => 'menu'; #
use Wx qw (wxITEM_NORMAL wxITEM_CHECK wxITEM_RADIO wxBITMAP_TYPE_XPM);
use Wx::Event qw (EVT_MENU EVT_MENU_OPEN EVT_MENU_HIGHLIGHT EVT_SET_FOCUS);

sub _set{$Kephra::app{(APPROOT)}{$_[0]}{ref} = $_[1] if ref $_[1] eq 'Wx::Menu'}
sub _get{$Kephra::app{(APPROOT)}{$_[0]}{ref} }

# ready menu for display
sub ready {
	my $id = shift;
	if (ref $Kephra::app{(APPROOT)}{$id} eq 'HASH'){
		my $menu = $Kephra::app{(APPROOT)}{$id};

		if ($menu->{absolete} and $menu->{update})
			{ $menu->{absolete} = 0 if $menu->{update}() }

		if (ref $menu->{onopen} eq 'HASH')
			{ $_->() for values %{$menu->{onopen}} }

		_get($id);
	}
}
sub set_absolete{ $Kephra::app{(APPROOT)}{$_[0]}{absolete} = 1 }
sub not_absolete{ $Kephra::app{(APPROOT)}{$_[0]}{absolete} = 0 }
sub is_absolete { $Kephra::app{(APPROOT)}{$_[0]}{absolete} }
sub set_update {
	$Kephra::app{(CFGROOT)}{$_[0]}{update} = $_[1] if ref $_[1] eq 'CODE'
}
sub no_update  {
	delete $Kephra::app{(APPROOT)}{$_[0]}{update} 
		if exists $Kephra::app{(APPROOT)}{$_[0]}
}

sub add_onopen_check{
	return until ref $_[2] eq 'CODE';
	$Kephra::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] } = $_[2];
}
sub del_onopen_check{
	return until $_[1];
	delete $Kephra::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] }
		if exists $Kephra::app{ (APPROOT) }{ $_[0] }{onopen}{ $_[1] };
}

# 
sub create_dynamic {
	my $menu_id = shift;
	my $menu_name = shift;

	if ($menu_name eq '&file_history'){
		set_update($menu_id, sub {
			my @menu_data;
		});
	} elsif ($menu_name eq '&document_change'){
		my $static_items = 0;
		my @menu_data;
		my $cmd_data;
		for (qw (document-change-prev
				 document-change-next 
				 document-change-back) 
			) {
			$cmd_data = Kephra::App::CommandList::get_cmd_properties($_);
			next unless ref $cmd_data eq 'HASH';
			my $item = \%{$menu_data[$static_items++]};
			$item->{type} = 'item';
			for ('call','label','help','icon'){
				$item->{$_} = $cmd_data->{$_} if $cmd_data->{$_}
			}
		}
		# create separator
		$menu_data[$static_items++]{type} = '';

		set_update($menu_id, sub {
			return unless exists $Kephra::temp{document}{buffer};
			pop @menu_data while @menu_data > $static_items;
			my $names = &Kephra::Document::_get_all_names;
			my $pathes = &Kephra::Document::_get_all_pathes;
			my $cd_nr = Kephra::Document::_get_current_nr();
			my $space = ' ';
			my $untitled = $Kephra::localisation{app}{general}{untitled};
			for my $nr (0 .. @$names-1){
				my $item = \%{$menu_data[$nr+$static_items]};
				$space = '' if $nr == 9;
				$item->{type} = 'radioitem';
				$item->{label} = $names->[$nr] 
					? $space.($nr+1)." - $names->[$nr] \t - $pathes->[$nr]"
					: $space.($nr+1)." - <$untitled> \t -";
				$item->{help} = '';
				$item->{call} = eval 'sub {Kephra::Document::Change::to_nr('.$nr.')}';
				$item->{state}= $nr == $cd_nr ? 1 : 0;
			}
			eval_data($menu_id, \@menu_data);
		});

		Kephra::App::EventList::add_call (
			'document.list', $menu_id.'_menu', sub { set_absolete($menu_id) }
		);

		add_onopen_check( $menu_id, 'select', sub {
			my $menu = _get($menu_id);
			my $check_nr = Kephra::Document::_get_current_nr() + $static_items;
			for ($static_items..$static_items + Kephra::Document::_get_last_nr()){
				$check_nr == $_
					? $menu->FindItemByPosition($_)->Check(1)
					: $menu->FindItemByPosition($_)->Check(0);
			}
			#print "update docchange menu\n";
			#print $menu->FindItemByPosition
			#	(Kephra::Document::_get_current_nr() + $static_items)->GetId." \n";
			#$menu->FindItemByPosition
			#	(Kephra::Document::_get_current_nr() + $static_items)->Check(1);
			#$menu->Check ( $menu->FindItemByPosition
			#	($static_items+Kephra::Document::_get_current_nr())->GetId, 1
			#);
		});
	}
	eval_data($menu_id);
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
			$item{label} = $Kephra::localisation{'app'}{'menu'}{$sub_id};
			$item{data} = assemble_data_from_def($item_def->{$sub_id}); 
		# creating data
		} elsif ($item_def eq '' or $item_def eq 'separator'){
			$item{type} = ''
		} else {
			$pos = index $item_def, ' ';
			next if $pos == -1;
			$item{type} = substr $item_def, 0, $pos;
			$cmd_name = substr $item_def, $pos+1;
			if ($item{type} eq 'menu'){
				$item{id} = $cmd_name;
				$item{label}= $Kephra::localisation{'app'}{'menu'}{$cmd_name};
			} else {
				$cmd_data = Kephra::App::CommandList::get_cmd_properties( $cmd_name );
				# skipping when command call is missing
				next unless ref $cmd_data and exists $cmd_data->{call};
				for ('call','enable','state','label','help','icon'){
					$item{$_} = $cmd_data->{$_} if $cmd_data->{$_}
				}
			}
		}
		push @mds, \%item;
	}
	return \@mds;
}


# eval menu data structures (MDS) to wxMenus
sub eval_data {
	my $menu_id = shift;
	return unless defined $menu_id;
	my $menu_data = shift;
	my $menu = Wx::Menu->new();

	unless (ref $menu_data eq 'ARRAY') {
		_set($menu_id, $menu); 
		return $menu;
	}
	my $win = Kephra::App::Window::_get();

	my $kind;
	my $item_id = exists $Kephra::app{(APPROOT)}{$menu_id}{item_id}
		? $Kephra::app{(APPROOT)}{$menu_id}{item_id}
		: $Kephra::app{GUI}{masterID}++ * 100;
	$Kephra::app{(APPROOT)}{$menu_id}{item_id} = $item_id;

	for my $item_data (@$menu_data){
		if (not $item_data->{type} or $item_data->{type} eq 'separator'){
			$menu->AppendSeparator;
		} elsif ($item_data->{type} eq 'menu'){
			if (ref $item_data->{data} eq 'ARRAY'){
				$menu->Append( $item_id++, $item_data->{label}, 
						eval_data( $item_data->{id}, $item_data->{data} ));
			} elsif ( $item_data->{id} and $item_data->{label}){
				$menu->Append
					($item_id++, $item_data->{label}, _get( $item_data->{id} ));
			}
		} else {
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
				if ref $item_data->{icon} eq 'Wx::Bitmap'
				and $item_data->{type} eq 'item';
			
			add_onopen_check( $menu_id, 'enable '.$item_id, sub {
				$menu_item->Enable( $item_data->{enable}() );
			} ) if ref $item_data->{enable} eq 'CODE';
			add_onopen_check( $menu_id, 'check '.$item_id, sub {
				$menu_item->Check( $item_data->{state}() )
			} ) if ref $item_data->{state} eq 'CODE';

			EVT_MENU          ($win, $item_id, $item_data->{call} );
			EVT_MENU_HIGHLIGHT($win, $item_id, sub {
				Kephra::App::StatusBar::info_msg( $item_data->{help} )
			});
			$menu->Append( $menu_item );
			$item_id++; 
		}
	}

	Kephra::App::EventList::add_call('menu.open', $menu, sub {ready($menu_id)} );
	_set($menu_id, $menu);
	return $menu;
}

1;