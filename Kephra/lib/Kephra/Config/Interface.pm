package Kephra::Config::Interface;
$VERSION = '0.01';
 
use strict;


sub load_data {
	my $conf = $Kephra::config{'app'};
	my $conf_path = $Kephra::temp{path}{config};

	# localisation
	%Kephra::localisation = 
		%{ Kephra::Config::File::load( $conf_path.$conf->{'localisation_file'} ) };
	# load embedded localisation for emergency cases
	unless (%Kephra::localisation) {
		require Kephra::Config::Embedded;
		%Kephra::localisation = %{&Kephra::Config::Embedded::get_english_localisation};
	}


	#try du load from cache first
	if ($conf->{commandlist}{cache}{use}){
	} else {
	}

	Kephra::App::CommandList::assemble_data();
	store_cache();
	#delete $Kephra::localisation {'commandlist'};
}

sub del_temp_data {
}

sub store_cache {
}

1;