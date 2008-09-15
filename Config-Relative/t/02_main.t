#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec       ();
use Config::Relative ();

if ( eval { require YAML::Tiny; } ) {
	plan( tests => 11 );
} else {
	plan( skip_all => 'YAML::Tiny is not available' );
}

my $CONFIG_ROOT = File::Spec->catdir( 't', 'data' );
ok( -d $CONFIG_ROOT, 'Test directory exists' );
my $CONFIG_FILE = File::Spec->catfile( 't', 'data', 'Foo-Bar.conf' );
ok( -f $CONFIG_FILE, 'Test file exists' );





#####################################################################
# Load a config file manually

SCOPE: {
	my $config1 = Config::Relative->new(
		config_driver => 'YAML::Tiny',
		config_file   => $CONFIG_FILE,
	);
	isa_ok( $config1, 'Config::Relative' );
	my $config3 = Config::Relative->new(
		config_driver => 'YAML::Tiny',
		config_root   => $CONFIG_ROOT,
		config_file   => $CONFIG_FILE,
	);
	isa_ok( $config3, 'Config::Relative' );

	# All three should be the same
	is_deeply( $config1, $config3, 'Configuration objects match' );
}

# Again with a test subclass
SCOPE: {
	package Foo::Bar;

	use base 'Config::Relative';

	use vars qw{$VERSION};
	BEGIN {
		$VERSION = '0.02';
	}

	sub foo {
		$_[0]->{foo};
	}

	sub file1 {
		$_[0]->relative_file(
			$_[0]->{file}, $_[0]->config_root
		);
	}

	sub file2 {
		$_[0]->relative_file(
			$_[0]->{file},
		);
	}

	1;
}

SCOPE: {
	my $config1 = Foo::Bar->new(
		config_driver => 'YAML::Tiny',
		config_root   => $CONFIG_ROOT,
		config_file   => $CONFIG_FILE,
	);
	isa_ok( $config1, 'Foo::Bar' );
	my $config2 = Foo::Bar->new(
		config_driver => 'YAML::Tiny',
		config_root   => $CONFIG_ROOT,
	);
	isa_ok( $config2, 'Foo::Bar' );
	is_deeply( $config1, $config2, 'Configuration objects match' );

	# Check we get the right file
	my $file1 = $config1->file1;
	ok( -f $file1, '->file1 returns a value that exists' );
	my $file2 = $config1->file2;
	ok( -f $file2, '->file2 returns a value that exists' );
	is( $file1, $file2, 'Explicit and implicit versions match' );
}
