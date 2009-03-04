#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 8;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use Perl::Dist::WiX::Base::Fragment;

#####################################################################
#

my $fragment_1 = Perl::Dist::WiX::Base::Fragment->new(
    id => 'Test');
ok( $fragment_1, '->new returns true' );

eval {
    my $fragment_2 = Perl::Dist::WiX::Base::Fragment->new(
        id => undef);
};

like($@, qr(invalid: id), '->new catches bad id' );

eval {
    my $s = q{};
    my $fragment_3 = Perl::Dist::WiX::Base::Fragment->new(
        id => q{ },
        directory => \$s);
};

like($@, qr(invalid: directory), '->new catches bad directory' );

my $fragment_test_1 = [
  'Perl::Dist::WiX::Base::Fragment',
  {
    'Perl::Dist::WiX::Base::Fragment' => {
                                           'components' => [],
                                           'id' => 'Test',
                                           'directory' => 'TARGETDIR'
                                         },
    'Perl::Dist::WiX::Misc' => {
                                 'sitename' => 'www.perl.invalid',
                                 'trace' => 0,
                                 'siteguid' => undef
                               }
  }
];

is_deeply( $fragment_1->dump(), $fragment_test_1, 'Object created correctly' );

isa_ok( $fragment_1, 'Perl::Dist::WiX::Base::Fragment' );
isa_ok( $fragment_1, 'Perl::Dist::WiX::Misc' );

is( $fragment_1->as_string(0), q[], '->as_string is empty (no components added)' );

eval {
    my $s = q{};
    $fragment_1->add_component($s);
};

like($@, qr(invalid: component), '->add_component catches bad component' );


