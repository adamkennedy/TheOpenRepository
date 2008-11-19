package Perl::Dist::Parrot;

use 5.008;
use strict;
use warnings;
use Perl::Dist::Vanilla ();

use vars qw{$VERSION @ISA};
BEGIN {
        $VERSION  = '0.01';
	@ISA      = 'Perl::Dist::Vanilla';
}





#####################################################################
# Configuration

sub new {
	shift->SUPER::new(
		app_id               => 'parrot',
		app_name             => 'Vanilla Parrot',
		app_publisher        => 'Vanilla Perl Project',
		app_publisher_url    => 'http://vanillaperl.org/',
		app_ver_name         => 'Vanilla Parrot 5.8.8 Alpha 1',
		output_base_filename => 'vanilla-parrot-5.8.8-alpha-1',
		image_dir            => 'C:\\parrot',

		# Build both exe and zip versions
		exe                  => 1,
		zip                  => 1,

		@_,
	);
}





#####################################################################
# Custom Installation

sub install_custom {
	die "CODE INCOMPLETE";
}

1;
