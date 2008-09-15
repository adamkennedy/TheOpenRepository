package Perl::Dist::Chocolate;

use 5.005;
use strict;
use Perl::Dist::Strawberry ();

use vars qw{VERSION};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Perl::Dist::Strawberry';
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'chocolateperl',
		app_name          => 'Chocolate Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\chocolate',

		# Build both exe and zip versions
		exe               => 1,
		zip               => 0,
		@_,
	);
}

# Lazily default the full name.
# Supports building multiple versions of Perl.
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human . ' Alpha 1';
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl-' . $_[0]->perl_version_human . '-alpha-1';
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	die "Perl 5.8.8 is not available in Chocolate Perl";
}

sub install_perl_5100 {
	my $self = shift;
	$self->SUPER::install_perl_5100(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Chocolate CPAN_Config_5100.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	# All of the GUI tools need WxWidgets
	$self->install_wx;

	return 1;
}





#####################################################################
# Installation Methods

sub install_wx {
	my $self = shift;

	# The underlying alien package installs quite happily
	# as a normal module.
	$self->install_module(
		name => 'Alien::wxWidgets',
	);

	# The main distribution has to be installed without being
	# passed the normal INC/LIBS params.
	$self->install_distribution(
		name             => 'MBARBON/Wx-0.84.tar.gz',
		makefilepl_param => [],
	);

	return 1;
}

1;
