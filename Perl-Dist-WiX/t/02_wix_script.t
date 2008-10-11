#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 24;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use Perl::Dist::WiX ();





#####################################################################
# Check for the binary application detection support

ok( Perl::Dist::WiX::Script->wix_key, '->wix_key ok' );

my @wix_registry  = Perl::Dist::WiX::Script->wix_registry;
ok( scalar(@wix_registry), '->wix_registry returns true' );

isa_ok( $wix_registry[0], 'Win32::TieRegistry' );
my $wix_tiedref = $wix_registry[0]->TiedRef;
isa_ok( $wix_tiedref, 'Win32::TieRegistry' );

# Do we have version 3.0?
isa_ok( $wix_tiedref->{'3.0/'}, 'Win32::TieRegistry' );

# Get the install root
my $wix_root = Perl::Dist::WiX::Script->wix_root;
ok( $wix_root, 'InstallRoot found in the registry' );
ok( -d $wix_root, 'InstallRoot directory exists' );

# Confirm the executables we need exist
my $candle = Perl::Dist::WiX::Script->wix_binary('candle');
my $light  = Perl::Dist::WiX::Script->wix_binary('light');
ok(    $candle, 'Got candle path' );
ok( -f $candle, 'Candle exists'   );
ok(    $light,  'Got light path'  );
ok( -f $light,  'Light exists'    );





#####################################################################
# Check the constructor

my %params = (
	product_name         => 'Product Name',
	product_manufacturer => 'Product Manufacturer',
	product_version      => '1.0.0.0',
	source_dir           => 'Source Directory',
	output_dir           => 'Output Directory',
);

SCOPE: {
	my $script = Perl::Dist::WiX::Script->new( %params );
	isa_ok( $script, 'Perl::Dist::WiX::Script' );
	foreach my $key ( keys %params ) {
		is( $script->$key(), $params{$key}, "->$key ok" );
	}
	ok( -f $script->bin_candle, '->bin_candle exists' );
	ok( -f $script->bin_light,  '->bin_light exists'  );
	is(    $script->product_id, '*', '->product_id ok' );
	is(    $script->product_upgrade_code, undef, '->product_upgrade_code ok' );
	like(
		$script->output_basename,
		qr/^ProductName\-1\.0\.0\.0-\d{8}$/,
		'->product_basename ok',
	);
}

SCOPE: {
	# Repeat with an explicit output_basename
	my $script = Perl::Dist::WiX::Script->new(
		%params,
		output_basename => 'FooBar-1.2.3.4',
	);
	isa_ok( $script, 'Perl::Dist::WiX::Script' );
	is( $script->output_basename, 'FooBar-1.2.3.4', '->output_basename ok' );
}
