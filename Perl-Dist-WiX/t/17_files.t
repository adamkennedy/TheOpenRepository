#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::Files;
require Perl::Dist::WiX::DirectoryTree;

# TODO: Flesh out this test.

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 8;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $tree_1 = Perl::Dist::WiX::DirectoryTree->new(
    trace => 100,
);

my $files_1 = Perl::Dist::WiX::Files->new(
    trace          => 100,
    id             => 'TestFiles',
    directory_tree => $tree_1,
    sitename       => 'www.test.site.invalid',
);

ok( defined $files_1, 'creating a P::D::W::Files' );

isa_ok( $files_1, 'Perl::Dist::WiX::Files', 'The files list' );
isa_ok( $files_1, 'Perl::Dist::WiX::Base::Fragment', 'The files list' );
isa_ok( $files_1, 'Perl::Dist::WiX::Misc', 'The files list' );

eval {
    my $files_2 = Perl::Dist::WiX::Files->new(
        trace          => 100,
        id             => undef,
        directory_tree => $tree_1,
        sitename       => 'www.test.site.invalid',
    );
};

like($@, qr(Missing or invalid id), '->new catches bad id' );

eval {
    my $files_3 = Perl::Dist::WiX::Files->new(
        trace          => 100,
        id             => 'TestFiles',
        directory_tree => undef,
        sitename       => 'www.test.site.invalid',
    );
};

like($@, qr(Missing or invalid directory_tree), '->new catches bad directory_tree' );

eval {
    my $files_4 = Perl::Dist::WiX::Files->new(
        trace          => 100,
        id             => 'TestFiles',
        directory_tree => $tree_1,
        sitename       => undef,
    );
};

like($@, qr(Missing or invalid sitename), '->new catches bad sitename' );

is( $files_1->as_string, q{}, '->as_string with no components' );
