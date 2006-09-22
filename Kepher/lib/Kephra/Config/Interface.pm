package Kepher::Config::Interface;
$VERSION = '0.01';
 
use strict;


sub load_data {
	my $conf = $Kepher::config{'app'};
	my $conf_path = $Kepher::internal{path}{config};

	# localisation
	%Kepher::localisation = 
		%{ Kepher::Config::File::load( $conf_path.$conf->{'localisation_file'} ) };
	# load embedded localisation for emergency cases
	unless (%Kepher::localisation) {
		require Kepher::Config::Embedded;
		%Kepher::localisation = %{&Kepher::Config::Embedded::get_english_localisation};
	}


	#try du load from cache first
	if ($conf->{commandlist}{cache}{use}){
	} else {
	}

	Kepher::App::CommandList::assemble_data();
	store_cache();
	#delete $Kepher::localisation {'commandlist'};
}

sub del_temp_data {
}

sub store_cache {
}

1;