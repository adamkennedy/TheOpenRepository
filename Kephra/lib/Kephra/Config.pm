package Kephra::Config;
our $VERSION = '0.28';

# low level config manipulation

use strict;


# single node manipulation
sub _convert_node_2_AoH {
	my $node = shift;
	if ( ref $$node eq 'ARRAY'  ) {
		return $$node;
	} elsif ( ref $$node eq 'HASH' ) {
		my %temp_hash = %{$$node};
		push( my @temp_array, \%temp_hash );
		return $$node = \@temp_array;
	} elsif ( ref $$node eq '' ) {
		my @temp_array = ();
		return $$node = \@temp_array;
	}
}

sub _convert_node_2_AoS {
	my $node = shift;
	if ( 'ARRAY'  eq ref $$node ) {
		return $$node;
	} elsif ( 'SCALAR' eq ref $node )  {
		if ($$node) {
			my $temp = $$node;
			push( my @temp_array, $temp );
			return $$node = \@temp_array;
		} else {
			my @temp_array = ();
			return $$node = \@temp_array;
		}
	}
}

sub _hex2dec_color_array {
	my $color  = shift;
	my @values = (
		hex( substr( $color, 0, 2 ) ),
		hex( substr( $color, 2, 2 ) ),
		hex( substr( $color, 4, 2 ) )
	);
	#split /,/, $color; #if ($#values == 0) {@values =
	return \@values;
}

sub set_xp_style {
	my $xp_def_file = "$^X.manifest";
	if ( $^O eq 'MSWin32' ) {
		if (    ( $Kephra::config{'app'}{'xp_style'} eq '1' )
			and ( !-r $xp_def_file ) ) {
			require Kephra::Config::Embedded;
			&Kephra::Config::Embedded::drop_xp_style_file($xp_def_file);
		}
		if (    ( $Kephra::config{'app'}{'xp_style'} eq '0' )
			and ( -r $xp_def_file ) ) {
			unlink $xp_def_file;
		}
	}
}

sub build_fileendings2syntaxstyle_map {
	foreach ( keys %{ $Kephra::config{'file'}{'endings'} } ) {
		my $language_id = $_;
		my @fileendings
			= split( /\s+/, $Kephra::config{'file'}{'endings'}{$language_id} );
		foreach (@fileendings) {
			$Kephra::temp{'file'}{'end2langmap'}{$_} = $language_id;
		}
	}
}

sub build_fileendings_filterstring {
	my $files = $Kephra::localisation{'dialog'}{'file'}{'files'};
	my $all   = "$Kephra::localisation{dialog}{general}{all} $files (*.*)|*.*";
	$Kephra::temp{'file'}{'filterstring'}{'all'} = $all;
	foreach ( keys %{ $Kephra::config{'file'}{'filter'} } ) {
		my ( $filter_id, $file_filter ) = ( $_, '' );
		my $filter_name = ucfirst($filter_id);
		my @language_ids
			= split( /\s+/, $Kephra::config{'file'}{'filter'}{$filter_id} );
		foreach (@language_ids) {
			my @fileendings
				= split( /\s+/, $Kephra::config{'file'}{'endings'}{$_} );
			foreach (@fileendings) { $file_filter .= "*.$_;"; }
		}
		chop($file_filter);
		$Kephra::temp{'file'}{'filterstring'}{'all'}
			.= "|$filter_name $files ($file_filter)|$file_filter";
	}
	$Kephra::temp{'file'}{'filterstring'}{'config'}
		= "Config $files (*.conf)|*.conf|$all";
	$Kephra::temp{'file'}{'filterstring'}{'scite'}
		= "Scite $files (*.ses)|*.ses|$all";
}

sub _map2hash {
	my ( $style, $types_str ) = @_;
	my $stylemap = {};                        # holds the style map
	my @types = split( /\s+/, $types_str );
	foreach (@types) { $$stylemap{$_} = $style; }
	return ($stylemap);
}

sub _lc_utf {
	my $uc = shift;
	my $lc = "";
	for ( 0 .. length($uc) - 1 ) {
		$lc .= lcfirst( substr( $uc, $_, 1 ) );
	}
	$lc;
}
#pce:dialog::msg_box(undef,$mode,'');
#Wx::wxUNICODE()

1;
