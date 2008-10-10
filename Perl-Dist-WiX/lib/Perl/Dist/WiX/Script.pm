package Perl::Dist::WiX::Script2;

use 5.008;
use Moose;
use File::Spec             ();
use Win32::TieRegistry     ();
use Perl::Dist::WiX::Types ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub wix_key {
	'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows Installer XML';
}

sub wix_registry {
	Win32::TieRegistry->new( $_[0]->wix_key => {
		Access    => Win32::TieRegistry::KEY_READ(),
		Delimiter => '/',
	} );
}

sub wix_root {
	$_[0]->wix_registry->TiedRef->{'3.0/'}->{'/InstallRoot'};
}

sub wix_binary {
	File::Spec->catfile( $_[0]->wix_root, "$_[1].exe" );
}





#####################################################################
# External Application Integration

has bin_candle => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => sub {
		$_[0]->wix_binary('candle')
	},
);

has bin_light => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => sub {
		$_[0]->wix_binary('light')
	},
);





#####################################################################
# Product Properties

has product_id => (
	is       => 'ro',
	isa      => 'WinAutogenGuid',
	required => 1,
	default  => '*',
);

has product_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has product_manufacturer => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has product_upgrade_code => (
	is       => 'ro',
	isa      => 'WinGuid',
);

has product_version => (
	is       => 'ro',
	isa      => 'WinVersion',
	required => 1,
);





#####################################################################
# Process Properties

has source_dir => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has output_dir => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has output_basename => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	lazy     => 1,
	default  => sub {
		my $self     = shift;
		my @date     = localtime;
		my $basename = $self->product_name
			. '-'
			. $self->product_version
			. '-'
			. sprintf( "%04d%02d%02d",
				$date[5] + 1900,
				$date[4] + 1,
				$date[3],
			);
		$basename =~ s/\s//g;
		return $basename;
	},
);

__PACKAGE__->meta->make_immutable;

1;
