package KEPHER::Config::Interface;
$VERSION = '0.01';
 
use strict;


sub load_data {
	my $conf = $KEPHER::config{'app'};
	my $conf_path = $KEPHER::internal{path}{config};

	# localisation
	%KEPHER::localisation = 
		%{ KEPHER::Config::File::load( $conf_path.$conf->{'localisation_file'} ) };
	# load embedded localisation for emergency cases
	unless (%KEPHER::localisation) {
		require KEPHER::Config::Embedded;
		%KEPHER::localisation = %{&KEPHER::Config::Embedded::get_english_localisation};
	}


	#try du load from cache first
	if ($conf->{commandlist}{cache}{use}){
	} else {
	}

	KEPHER::App::CommandList::assemble_data();
	store_cache();
	#delete $KEPHER::localisation {'commandlist'};
}

sub del_temp_data {
}

sub store_cache {
}

1;