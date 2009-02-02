package Alien::Bat2ExeConverter;

use 5.008;
use strict;
use warnings;
use Carp           ();
use File::Which    ();
use File::ShareDir ();

our $VERSION = '0.01';

sub bat2exe_path {
	# Check for the installed version
	my $installed = File::Which::which('Bat_To_Exe_Converter');
	return $installed if $installed;

	# Default to the bundled version
	File::ShareDir::dist_file(
		'Alien-Bat2ExeConverter',
		'Bat_To_Exe_Converter.exe',
	);
}

sub bat2exe {
	my %atr = @_;

	# Required input batch script
	my $bat = $param{bat};
	unless ( $bat and $bat =~ /\.bat$/ and -f $bat ) {
		Carp::croak("Missing or invalid bat file");
	}

	# Required output executable application
	my $exe = $param{exe};
	unless ( $exe and $exe =~ /\.exe$/ ) {
		Carp::croak("Missing or invalid exe file");
	}
	if ( -f $exe ) {
		Carp::croak("The target exe '$exe' already exists");
	}

	# Optional icon file
	my $ico = $param{ico} || '';
	if ( $ico and not -f $ico ) {
		Carp::croak("Invalid ico file");
	}

	# DOS or GUI application?
	my $dos = !! $param{dos};

	# Hand off to the executable
	my $bat2exe = bat2exe_path();
	
}

1;
