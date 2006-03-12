#!/usr/bin/perl -w

# Basic test that ONLY loads the modules to ensure that all the code compiles

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{TEST_HARNESS} ) {
		# Special fast option for CGI environment, as FindBin won't work in
		# the web environments of some web hosts.
		if ( $ENV{SCRIPT_FILENAME} and $ENV{SCRIPT_FILENAME} =~ /^(.+\/)/ ) {
			chdir catdir( $1, updir() );
		} else {
			require FindBin;
			chdir catdir( $FindBin::Bin, updir() );
			$FindBin::Bin = $FindBin::Bin; # Avoid a "only used once" warning
		}

		# Set the lib path if we aren't in a harness
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

# Define and check the GEOSOL_ROOT location
$ENV{GEOSOL_ROOT} = '/home/geosol/virtual/geologicalsolutions.com.au/http';
unless ( $ENV{GEOSOL_ROOT} and -d $ENV{GEOSOL_ROOT} ) {
	quit('GEOSOL_ROOT is not defined, or does not exist');
}

require GeoSol::Process::EmailSync;

# Create the new default object and run it
my $object = GeoSol::Process::EmailSync->default;
unless ( $object ) {
	quit('Failed to create default sync object');
}
unless ( $object->prepare ) {
	quit('Failed to prepare sync object');
}
unless ( $object->run ) {
	quit('Failed to run sync object');
}

quit();





#####################################################################
# Support Functions

sub quit {
	if ( $_[0] ) {
		message(shift);
		exit(255);
	} else {
		exit(0);
	}
}

my $cgi_header = 0;

sub message {
	my $message = shift;
	$message =~ s/[\012\015]+$/\n/;
	if ( $ENV{SCRIPT_FILENAME} ) {
		unless ( $cgi_header ) {
			print "Content-Type: text/plain\n\n";
			$cgi_header = 1;
		}

	}
	print $message;
	1;
}

1;
