package Kepher::App::CommandList;
$VERSION = '0.06';

use strict;
use constant APPROOT => 'command';
use constant CFGROOT => 'commandlist';
use Wx qw(wxBITMAP_TYPE_XPM);


sub _get_config{ $Kepher::config{'app'}{'commandlist'} }

sub assemble_data{
	# get info from global configs and load commandlist conf file
	my $config = _get_config();
	my $file_name = $Kepher::internal{path}{config} . $config->{file};
	my $cmd_list_def = Kepher::Config::File::load($file_name);
	if ($config->{node} and exists $cmd_list_def->{ $config->{node} }) {
		$cmd_list_def = $cmd_list_def->{$config->{node}};
	} else { return }#


	# copy data of a hash structures into specified commandlist leafes
	_copy_conf_values($cmd_list_def->{call},  'call');
	_copy_conf_values($cmd_list_def->{enable},'enable');
	_copy_conf_values($cmd_list_def->{enable_event},'enable_event');
	_copy_conf_values($cmd_list_def->{state}, 'state');
	_copy_conf_values($cmd_list_def->{state_event}, 'state_event');
	_copy_conf_values($cmd_list_def->{key},   'key');
	_copy_conf_values($cmd_list_def->{icon},  'icon');
	_copy_conf_values($Kepher::localisation{(CFGROOT)}{label},'label');
	_copy_conf_values($Kepher::localisation{(CFGROOT)}{help}, 'help');
	_create_keymap()
}

sub _copy_conf_values {
	no strict;
	my $root_node = shift;                # source
	local $target_leafe = shift;
	local ($leaf_type, $cmd_id);
	local $list = \%{$Kepher::app{(APPROOT)}}; # commandlist data
	_parse_node($root_node, '') if ref $root_node eq 'HASH';
}

sub _parse_node{
	my $parent_node = shift;
	my $parent_id = shift;
	no strict;
	for (keys %$parent_node){
		$cmd_id = $parent_id . $_; 
		$leaf_type = ref $parent_node->{$_};
		if (not $leaf_type) {
			$list->{$cmd_id}{$target_leafe} = $parent_node->{$_}
		} elsif ($leaf_type eq 'HASH'){
			_parse_node($parent_node->{$_}, "$cmd_id-")
		}
	}
}

sub _create_keymap{
	my $list = \%{$Kepher::app{(APPROOT)}};
	my ($item_data, $rd, $kc, $kn, $i, $char); #rawdata, keycode
	my $shift = $Kepher::localisation{key}{meta}{shift}.'+';
	my $alt   = $Kepher::localisation{key}{meta}{alt}.'+';
	my $ctrl  = $Kepher::localisation{key}{meta}{ctrl}.'+';
	my %keycode_map = (
		back => 8, tab => 9, enter => 13, esc => 27, space => 32,
		'#' => 47,
		tilde => 92, del=> 127,
		pgup => 312, pgdn => 313, end =>314, home => 315, 
		left => 316, up => 317, right => 318, down => 319,
		ins => 324,
		f1 => 342, f2 => 343, f3 => 344,  f4 => 345,  f5 => 346,  f6 => 347,
		f7 => 348, f8 => 349, f9 => 350, f10 => 351, f11 => 352, f12 => 353,
		numpad_enter => 372
	);
	for (keys %$list){
		$item_data = $list->{$_};
		if (exists $item_data->{key}){
			$rd = $item_data->{key};
			$kn = '';
			$kc = 0;
			while (){
				$i = index $rd, '+';
				last unless  $i > 0;
				$char = lc substr $rd, 0, 1;
				if    ($char eq 's') {$kn .= $shift; $kc += 1000}
				elsif ($char eq 'c') {$kn .= $ctrl;  $kc += 2000}
				elsif ($char eq 'a') {$kn .= $alt;   $kc += 4000}
				$rd = substr $rd, $i + 1;
			}
			if (exists $Kepher::localisation{key}{$rd})
				{$kn .= $Kepher::localisation{key}{$rd}}
			else {$kn .= ucfirst $rd}
			$item_data->{label} .= "\t $kn "; # adding key name to label
			if (length ($rd)  == 1) { $kc += ord uc $rd } #
			else                    { $kc += $keycode_map{$rd} } #
			$item_data->{key} = $kc;
		}
	}
}

sub eval_data{
	my $list = \%{$Kepher::app{(APPROOT)}};
	my $ico_dir = $Kepher::internal{path}{config}.$Kepher::config{app}{iconset_path};
	my $keymap = \@{$Kepher::app{editpanel}{keymap}};

	my ($item_data, $ico_path);
	for (keys %$list){
		$item_data = $list->{$_};
		if ($item_data->{call}){
			if ($item_data->{key}){
				$keymap->[$item_data->{key}] = $item_data->{call} = 
					eval 'sub {'.$item_data->{call}.'}';
			} else {
				$item_data->{call} = eval 'sub {'.$item_data->{call}.'}';
			}
		}
		$item_data->{enable} = eval 'sub {'.$item_data->{enable}.'}'
			if $item_data->{enable};
		$item_data->{state} = eval 'sub {'.$item_data->{state}.'}'
			if $item_data->{state};
		next unless $item_data->{icon};
		$ico_path = $ico_dir . $item_data->{icon};
		$item_data->{icon} = Wx::Bitmap->new( $ico_path, wxBITMAP_TYPE_XPM)
			if -e $ico_path;
#			Wx::Image->new($ico_path, wxBITMAP_TYPE_XPM)->Scale( 15, 15 ) 
	}
}

sub get_cmd_properties{
	my $cmd_id = shift;
	$Kepher::app{(APPROOT)}{$cmd_id} if ref $Kepher::app{(APPROOT)}{$cmd_id} eq 'HASH';
}

sub get_cmd_property{
	my $cmd_id = shift;
	my $leafe = shift;
	$Kepher::app{(APPROOT)}{$cmd_id}{$leafe}
		if ref $Kepher::app{(APPROOT)}{$cmd_id} eq 'HASH'
		and exists $Kepher::app{(APPROOT)}{$cmd_id}{$leafe};
}

sub del_data{
	#delete $Kepher::localisation{'commandlist'}
	#	if exists $Kepher::localisation{'commandlist'};
}

#(stat $dateiname)[9]
sub load_cache{}
sub store_cache {}

1;
