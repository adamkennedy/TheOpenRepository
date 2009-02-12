#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::Icons;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 7;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $icon_1 = Perl::Dist::WiX::Icons->new(
    trace  => 100,
);

ok( defined $icon_1, 'creating a P::D::W::Icons' );

isa_ok( $icon_1, 'Perl::Dist::WiX::Icons', 'The icons list' );
isa_ok( $icon_1, 'Perl::Dist::WiX::Misc', 'The icons list' );


is( $icon_1->as_string, q{}, '->as_string with no icons' );

$icon_1->add_icon('c:\testicon.ico');

my $icon_1_test = bless( {
  'trace' => 100,
  'icons' => [
    {
      'file' => 'c:\\testicon.ico',
      'id' => 'testicon.msi',
      'target_type' => 'msi'
    }
  ]
}, 'Perl::Dist::WiX::Icons' );

is_deeply($icon_1, $icon_1_test, 'Object created correctly.');

is( $icon_1->search_icon('c:\testicon.ico'), 'testicon.msi', '->search_icon' );

is( $icon_1->as_string, "  <Icon Id='I_testicon.msi' SourceFile='c:\\testicon.ico' />\n", '->as_string' );
