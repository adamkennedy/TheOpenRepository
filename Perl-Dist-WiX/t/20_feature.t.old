#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::Feature;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 10;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $feature_1 = Perl::Dist::WiX::Feature->new(
    trace       => 100,
    id          => 'Complete',
    title       => 'Complete',
    description => 'The complete program',
    level       => 0,
);

ok( defined $feature_1, 'creating a P::D::W::Feature' );

isa_ok( $feature_1, 'Perl::Dist::WiX::Feature' );
isa_ok( $feature_1, 'Perl::Dist::WiX::Misc' );

eval {
    my $feature_2 = Perl::Dist::WiX::Feature->new(
        trace       => 100,
        id          => undef,
        title       => 'Complete',
        description => 'The complete program',
        level       => 0,
    );
};

like($@, qr(Missing mandatory initializer 'id'), '->new catches bad id' );

eval {
    my $feature_2 = Perl::Dist::WiX::Feature->new(
        trace       => 100,
        id          => 'Complete',
        title       => undef,
        description => 'The complete program',
        level       => 0,
    );
};

like($@, qr(Missing mandatory initializer 'title'), '->new catches bad title' );

eval {
    my $feature_2 = Perl::Dist::WiX::Feature->new(
        trace       => 100,
        id          => 'Complete',
        title       => 'Complete',
        description => undef,
        level       => 0,
    );
};

like($@, qr(Missing mandatory initializer 'description'), '->new catches bad description' );

eval {
    my $feature_5 = Perl::Dist::WiX::Feature->new(
        trace       => 100,
        id          => 'Complete',
        title       => 'Complete',
        description => 'The complete program',
        level       => 'Wrong',
    );
};

like($@, qr(invalid: level), '->new catches bad level' );

is( $feature_1->as_string, q{}, '->as_string with no components' );

$feature_1->add_components('TestComponent');

is( $feature_1->get_componentrefs->[0], 'TestComponent', '->add_components' );

my $feature_1_test_string = <<'EOF';
<Feature Id='Complete' Title='Complete' Description='The complete program' Level='0'>
  <ComponentRef Id='C_TestComponent' />
</Feature>
EOF

is( $feature_1->as_string, $feature_1_test_string, '->as_string');
