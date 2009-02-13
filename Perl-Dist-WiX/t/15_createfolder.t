#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::CreateFolder;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 8;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $folder_1 = Perl::Dist::WiX::CreateFolder->new(
    trace     => 100,
    id        => 'TestID',
    directory => 'TestID',
    sitename  => 'www.test.site.invalid',
);

ok( defined $folder_1, 'creating a P::D::W::CreateFolder' );

isa_ok( $folder_1, 'Perl::Dist::WiX::CreateFolder' );
isa_ok( $folder_1, 'Perl::Dist::WiX::Base::Fragment' );
isa_ok( $folder_1, 'Perl::Dist::WiX::Base::Component' );

eval {
    my $folder_2 = Perl::Dist::WiX::CreateFolder->new(
        trace     => 100,
        id        => undef,
        directory => 'TestID',
        sitename  => 'www.test.site.invalid',
    );
};

like($@, qr(Missing or invalid id), '->new catches bad id' );

eval {
    my $folder_3 = Perl::Dist::WiX::CreateFolder->new(
        trace     => 100,
        id        => 'TestID',
        directory => 'TestID',
        sitename  => undef,
    );
};

like($@, qr(Missing or invalid sitename), '->new catches bad sitename' );

is( $folder_1->get_component_array, 'CreateTestID', '->get_component_array' );

my $folder_1_test_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_CreateTestID'>
    <DirectoryRef Id='D_TestID'>
      <Component Id='C_CreateTestID' Guid='47B5C556-9D29-3003-826B-932229FEE9CB'>
        <CreateFolder />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $folder_1->as_string, $folder_1_test_string, '->as_string');
