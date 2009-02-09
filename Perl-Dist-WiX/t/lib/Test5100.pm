package t::lib::Test5100;

use strict;
use Perl::Dist::WiX ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.12';
	@ISA     = 'Perl::Dist::WiX';
}





#####################################################################
# Configuration

sub app_name             { 'Test Perl'                }
sub app_ver_name         { 'Test Perl 1 alpha 1'      }
sub app_publisher        { 'Vanilla Perl Project'     }
sub app_publisher_url    { 'http://vanillaperl.org'   }
sub app_id               { 'testperl'                 }
sub output_base_filename { 'test-perl-5.10.0-alpha-1' }





#####################################################################
# Main Methods

sub new {
	return shift->SUPER::new(
		perl_version => 5100,
        trace => 102,
        build_number => 5,
		@_,
	);
}

sub install_custom {
	my $self = shift;
	$self->install_module( name => 'Config::Tiny' );
	return 1;
}

1;
