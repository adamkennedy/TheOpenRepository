package Perl::Dist::Parrot;

=pod

=head1 NAME

Perl::Dist::Parrot - Parrot and its languages for Win32

=head1 DESCRIPTION

This is an experimental distribution builder, aiming to create a usable
installer for Parrot (and Rakudo, the Perl 6 implementation) on Windows.

=cut

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

=pod

=head1 SUPPOT

There is no support.

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
