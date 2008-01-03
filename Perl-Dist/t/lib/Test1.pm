package t::lib::Test1;

use strict;
use base 'Perl::Dist::Inno';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90_02';
}





#####################################################################
# Configuration

sub app_name             { 'Test Perl'               }
sub app_ver_name         { 'Test Perl 1 alpha 1'     }
sub app_publisher        { 'Vanilla Perl Project'    }
sub app_publisher_url    { 'http://vanillaperl.org'  }
sub app_id               { 'testperl'                }
sub output_base_filename { 'test-perl-5.8.8-alpha-1' }





#####################################################################
# Main Methods

sub run {
	my $self = shift;

	# Just install a single binary
	$self->install_binary(
		name    => 'dmake',
		share   => 'Perl-Dist-Downloads dmake-4.8-20070327-SHAY.zip',
		license => {
			'dmake/COPYING'            => 'dmake/COPYING',
			'dmake/readme/license.txt' => 'dmake/license.txt',
		},
		install_to => {
			'dmake/dmake.exe' => 'dmake/bin/dmake.exe',	
			'dmake/startup'   => 'dmake/bin/startup',
		},
	);

	return 1;
}

sub trace { Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

1;
