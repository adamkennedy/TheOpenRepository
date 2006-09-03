package Kepher::Config::Interface;

use strict;
use File::Spec;

our $VERSION = '0.01';

sub load_data {
	my $conf      = $Kepher::config{app};
	my $conf_path = $Kepher::internal{path}{config};

	# localisation
	my $l = Kepher::Config::File::load(
		File::Spec->catfile( $conf_path, $conf->{localisation_file} ),
		);
	unless ( $l and %$l ) {
		require Kepher::Config::Embedded;
		$l = Kepher::Config::Embedded::get_english_localisation();
	}
	%Kepher::localisation = %$l;

	Kepher::App::CommandList::assemble_data();
}

1;