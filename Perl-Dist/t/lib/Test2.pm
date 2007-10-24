package t::lib::Test2;

use strict;
use base 'Perl::Dist';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Configuration

sub app_name             { 'Test Perl'               }
sub app_ver_name         { 'Test Perl 1 alpha 1'     }
sub app_publisher        { 'Vanilla Perl Project'    }
sub app_publisher_url    { 'http://vanillaperl.org'  }
sub app_id               { 'testperl'                }
sub output_base_filename { 'test-perl-5.8.8-alpha-1' }

# Always remove the old image
sub remove_image         { 1 }





#####################################################################
# Main Methods

sub run {
	my $self = shift;

	# Install the core binaries
	$self->install_binaries;

	# Install Perl 5.8.8
	$self->install_perl_588(
		name    => 'perl',
		share   => 'Perl-Dist-Downloads perl-5.8.8.tar.gz',
		license => {
			'perl-5.8.8/Readme'   => 'perl/Readme',
			'perl-5.8.8/Artistic' => 'perl/Artistic',
			'perl-5.8.8/Copying'  => 'perl/Copying',
		},
		unpack_to => 'perl',
		install_to => 'perl',
		extras     => {
			'extra\Config.pm' => 'lib\CPAN\Config.pm',
		}
	);

	return 1;
}

sub trace { 1 }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_perl_588 {
	return shift->SUPER::install_perl_588( @_, trace => sub { 1 } );
}

1;
