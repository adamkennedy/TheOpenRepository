#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 10;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use Perl::Dist::WiX::Files::Component;

#####################################################################
#

my $component_1 = Perl::Dist::WiX::Files::Component->new(
    filename => 'C:\\temp\\invalid.test',
    sitename => 'www.test.site.invalid',
);
ok( $component_1, '->new returns true' );

eval {
    my $component_2 = Perl::Dist::WiX::Files::Component->new(
        filename => undef,
        sitename => 'www.test.site.invalid',
    );
};

like($@, qr(Missing mandatory initializer 'filename'), '->new catches bad filename' );

isa_ok( $component_1, 'Perl::Dist::WiX::Files::Component' );
isa_ok( $component_1, 'Perl::Dist::WiX::Base::Component' );
isa_ok( $component_1, 'Perl::Dist::WiX::Misc' );

is($component_1->is_file('C:\\temp\\invalid.test'), 1, '->is_file true');
is($component_1->is_file('C:\\texp\\invalid.test'), 0, '->is_file false');

is($component_1->get_component_array, 'C_CDD41023_A3B0_3385_AD13_974E2A1220AE', '->get_component_array');

my $string_test_1 = '<Component Id=\'C_CDD41023_A3B0_3385_AD13_974E2A1220AE\' Guid=\'CDD41023-A3B0-3385-AD13-974E2A1220AE\'>
  <File Id=\'F_CDD41023_A3B0_3385_AD13_974E2A1220AE\' Source=\'C:\\temp\\invalid.test\' />
</Component>
';

is( $component_1->as_string, $string_test_1, '->as_string' );

eval {
    my $s = q{};
    $component_1->add_entry($s);
};

like($@, qr(Not adding a valid component), '->add_component catches bad component' );


