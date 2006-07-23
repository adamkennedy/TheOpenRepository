package PCE::Config::Interface;
$VERSION = '0.01';
 
use strict;


sub load_data {
	my $conf = $PCE::config{'app'};
	my $conf_path = $PCE::internal{path}{config};

	# localisation
	%PCE::localisation = 
		%{ PCE::Config::File::load( $conf_path.$conf->{'localisation_file'} ) };
	# load embedded localisation for emergency cases
	unless (%PCE::localisation) {
		require PCE::Config::Embedded;
		%PCE::localisation = %{&PCE::Config::Embedded::get_english_localisation};
	}


	#try du load from cache first
	if ($conf->{commandlist}{cache}{use}){
	} else {
	}

	PCE::App::CommandList::assemble_data();
	store_cache();
	#delete $PCE::localisation {'commandlist'};
}

sub del_temp_data {
}

sub store_cache {
}

1;