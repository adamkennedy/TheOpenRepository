package Kephra::Config::Interface;
$VERSION = '0.02';
 
use strict;


sub load_data {
	my $conf      = $Kephra::config{'app'};
	my $gui_store = $Kephra::temp{configfile};
	my $gui_ref   = $Kephra::temp{config};
	my $conf_path = $Kephra::temp{path}{config};

	# localisation
	%Kephra::localisation = 
		%{ Kephra::Config::File::load( $conf_path.$conf->{'localisation_file'} ) };
	# load embedded localisation for emergency cases
	unless (%Kephra::localisation) {
		require Kephra::Config::Embedded;
		%Kephra::localisation = 
			%{&Kephra::Config::Embedded::get_english_localisation};
	}

	# commandlist
	#Kephra::App::CommandList::load_cache() if $conf->{commandlist}{cache}{use};
	#Kephra::App::CommandList::load_data();
	Kephra::App::CommandList::assemble_data();
	#delete $Kephra::localisation {'commandlist'};

	#try du load from cache first
}

sub del_temp_data {
	
}

sub load_cache {}
sub store_cache {}

1;