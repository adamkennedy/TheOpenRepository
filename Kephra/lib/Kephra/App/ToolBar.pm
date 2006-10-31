package Kephra::App::ToolBar;
$VERSION = '0.05';

# central lib for gui toolbars
# storing, fetching, assemble data, creating regular button items

use strict;
use Wx qw(
		wxNullBitmap wxSIZE
		wxITEM_NORMAL  wxITEM_CHECK 
		wxTB_HORIZONTAL wxTB_DOCKABLE
	);
use Wx::Event qw( EVT_TOOL );
use constant APPROOT => 'toolbar'; 

sub _get{ $Kephra::app{(APPROOT)}{$_[0]}{ref} }
sub _set{ $Kephra::app{(APPROOT)}{$_[0]}{ref} = $_[1] if ref $_[1] eq 'Wx::ToolBar'}
sub _create_empty {
	return Wx::ToolBar->new( Kephra::App::Window::_get(),
			-1, [-1,-1], [-1,-1], wxTB_HORIZONTAL|wxTB_DOCKABLE );
}

sub create_new{
	my $bar_id = shift;
	my $bar_def = shift;
	_set ($bar_id, _create_empty());
	create($bar_id, $bar_def);
}

sub create {
	my $bar_id = shift;
	my $bar_def = shift;
	eval_data($bar_id, assemble_data_from_def($bar_def));
}

sub assemble_data_from_def {
	my $bar_def = shift;
	return unless ref $bar_def eq 'ARRAY';

	my @tbds = (); # toolbar data structure
	my $cmd_data;
#
	for my $item_def (@$bar_def){
		my %item;

		# skipping commented lines
		next if substr($item_def, -1) eq '#';

		# recursive call for submenus 
		if (ref $item_def eq 'HASH'){} 

		# "parsing" item data
		($item{type}, $item{id}, $item{size}) = split / /, $item_def;
		
		# skip separators
		if (not defined $item{type} or $item{type} eq 'separator'){
			$item{type} = '';
		# handle regular toolbar buttons
		} elsif( substr( $item{type}, -4) eq 'item' ) {
			$cmd_data = Kephra::App::CommandList::get_cmd_properties( $item{id} );
			# skipping when command call is missing
			next unless ref $cmd_data and exists $cmd_data->{call};
			for ('call','enable','enable_event','state', 'state_event','label',
				'help','icon'){
				$item{$_} = $cmd_data->{$_} if $cmd_data->{$_}
			}
			#$item{type} = 'item'if not $cmd_data->{state} and $item{type} eq 'checkitem';
		}
		push @tbds, \%item;
	}
	return \@tbds;
}

sub eval_data {
	my $bar_id = shift;
	my $bar_data = shift;
	my $bar = _get($bar_id);
	return $bar unless ref $bar_data eq 'ARRAY';

	my $win = Kephra::App::Window::_get();
	my $item_kind;
	my @rest_items = ();
	my $bar_item_id = exists $Kephra::app{(APPROOT)}{$bar_id}{item_id}
		? $Kephra::app{(APPROOT)}{$bar_id}{item_id}
		: $Kephra::app{GUI}{masterID}++ * 100;
	$Kephra::app{(APPROOT)}{$bar_id}{item_id} = $bar_item_id;

	for my $item_data (@$bar_data){
		if (not $item_data->{type} or $item_data->{type} eq 'separator'){
			$bar->AddSeparator;
		} elsif (ref $item_data->{icon} eq 'Wx::Bitmap'){
			if ($item_data->{type} eq 'checkitem'){
				$item_kind = $item_data->{state} ? wxITEM_CHECK : wxITEM_NORMAL
			} elsif ($item_data->{type} eq 'item'){
				$item_kind = wxITEM_NORMAL 
			} else { next }
			my $item_id = $bar_item_id++;
			my $tool = $bar->AddTool(
				$item_id, '', $item_data->{icon}, wxNullBitmap, 
				$item_kind, $item_data->{label} ,$item_data->{help}
			);
			EVT_TOOL ($win, $item_id, $item_data->{call});
			if (ref $item_data->{enable} eq 'CODE'){
				$tool->Enable( $item_data->{enable}() );
				Kephra::App::EventList::add_call ( 
					$item_data->{enable_event}, $tool, sub{
						$bar->EnableTool( $item_id, $item_data->{enable}() )
				} ) if exists $item_data->{enable_event};
			}
			if (ref $item_data->{state} eq 'CODE'
				and $item_data->{type} eq 'checkitem'){
				$bar->ToggleTool( $item_id, $item_data->{state}() );
				Kephra::App::EventList::add_call ( 
					$item_data->{state_event}, $tool, sub{
						$bar->ToggleTool( $item_id, $item_data->{state}() )
				} ) if exists $item_data->{state_event};
			}
		} else {
			$item_data->{pos} = $bar_item_id % 100 + @rest_items;
			push @rest_items, $item_data;
		}
	}
	#$bar->>SetRows(1); #$bar->SetMargins(1, 1);
	#$bar->SetToolBitmapSize([16,15]); #wxSIZE( 15,15 )
	$bar->Realize;
	$bar->SetRows(1);
	_set($bar_id, $bar);

	return \@rest_items;
}

1;
