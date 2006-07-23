package PCE::App::ToolBar;
$VERSION = '0.03';

use strict;
use Wx qw( wxNullBitmap  wxITEM_NORMAL  wxITEM_CHECK wxSIZE);
use Wx::Event qw( EVT_MENU );
use constant APPROOT => 'toolbar'; 

sub _get{ $PCE::app{(APPROOT)}{ $_[0] } }
sub _set{ $PCE::app{(APPROOT)}{ $_[0] } = $_[1] if ref $_[1] eq 'Wx::ToolBar'}


sub create {
	my $bar_id = shift;
	my $bar_def = shift;
	
	eval_data($bar_id, assemble_data_from_def($bar_def));
}

sub assemble_data_from_def {
	my $bar_def = shift;
	return unless ref $bar_def eq 'ARRAY';

	my @tbds = (); # toolbar data structure
	my ($cmd_name, $cmd_data, $type_name, $pos, $sub_id);
#
	for my $item_def (@$bar_def){

		# sorting commented lines out
		next if substr($item_def, -1) eq '#';
		my %item;
		
		if (ref $item_def eq 'HASH'){# recursive call for submenus
		# creating data
		} elsif ($item_def eq '' or $item_def eq 'separator'){
			$item{type} = ''
		} else {
			$pos = index $item_def, ' ';
			next if $pos == -1;
			$item{type} = substr $item_def, 0, $pos;
			$cmd_name = substr $item_def, $pos+1;
			$cmd_data = PCE::App::CommandList::get_cmd_properties( $cmd_name );
			# skipping when command call is missing
			next unless ref $cmd_data and exists $cmd_data->{call};
			for ('call','enable','enable_event','state', 'state_event','label','help','icon'){
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

	my $win = PCE::App::Window::_get();
	my $bar_item_id = exists $PCE::app{(APPROOT)}{item_id}
		? $PCE::app{(APPROOT)}{item_id}
		: $PCE::app{GUI}{masterID}++ * 100;
	$PCE::app{(APPROOT)}{item_id} = $bar_item_id;
	my $item_kind;

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
			EVT_MENU ($win, $item_id, $item_data->{call});
			if (ref $item_data->{enable} eq 'CODE'){
				$tool->Enable( $item_data->{enable}() );
				PCE::App::EventList::add_call ( 
					$item_data->{enable_event}, $tool, sub{
						$bar->EnableTool( $item_id, $item_data->{enable}() )
				} ) if exists $item_data->{enable_event};
			}
			if (ref $item_data->{state} eq 'CODE'
				and $item_data->{type} eq 'checkitem'){
				$bar->ToggleTool( $item_id, $item_data->{state}() );
				PCE::App::EventList::add_call ( 
					$item_data->{state_event}, $tool, sub{
						$bar->ToggleTool( $item_id, $item_data->{state}() )
				} ) if exists $item_data->{state_event};
			}
		}
	}
	#$bar->>SetRows(1);
	#$bar->SetMargins(1, 1);
	#$bar->SetToolBitmapSize([16,15]);
	#$bar->SetToolBitmapSize( wxSIZE( 15,15 ) );
	$bar->Realize;
	$bar->SetRows(1);
	_set($bar_id, $bar);
	return $bar;
}

1;
