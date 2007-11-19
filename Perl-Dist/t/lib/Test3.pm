package t::lib::Test3;

use strict;
use base 'Perl::Dist';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29_04';
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

sub run {
	my $self = shift;

	# Install the core binaries
	$self->install_c_toolchain;

	# Install the extra libraries
	$self->install_c_libraries;

	# Install Perl 5.10.0
	$self->install_perl_5100(
		name       => 'perl',
		url        => 'file://c|/devel/minicpan/authors/id/R/RG/RGARCIA/perl-5.10.0-RC1.tar.gz',
		unpack_to  => 'perl',
		license    => {
			'perl-5.10.0/Readme'   => 'perl/Readme',
			'perl-5.10.0/Artistic' => 'perl/Artistic',
			'perl-5.10.0/Copying'  => 'perl/Copying',
		},
		install_to => 'perl',
		# force      => 1,
	);

	# Install the CPAN configuration
	# $self->install_file(
	#	share      => 'Perl-Dist Config.pm',
	#	install_to => 'perl/lib/CPAN/Config.pm',
	# );

	# Install a test distro
	$self->install_distribution(
		name => 'ADAMK/Config-Tiny-2.10.tar.gz',
	);

	return 1;
}

sub trace { Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_perl_5100 {
	return shift->SUPER::install_perl_5100( @_, trace => sub { 1 } );
}

sub install_distribution {
	return shift->SUPER::install_distribution( @_, trace => sub { 1 } );
}

1;
