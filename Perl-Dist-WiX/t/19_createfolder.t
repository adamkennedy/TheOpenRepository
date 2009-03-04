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

require Perl::Dist::WiX::CreateFolder;

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
isa_ok( $folder_1, 'Perl::Dist::WiX::Misc' );

eval {
    my $folder_2 = Perl::Dist::WiX::CreateFolder->new(
        trace     => 100,
        id        => undef,
        directory => 'TestID',
        sitename  => 'www.test.site.invalid',
    );
};

like($@, qr(invalid: id), '->new catches bad id' );

is( $folder_1->get_component_array, 'CreateTestID', '->get_component_array' );

my $folder_1_test_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_CreateTestID'>
    <DirectoryRef Id='D_TestID'>
      <Component Id='C_CreateTestID' Guid='FB041D3B-4936-3E95-88A4-C82080C91974'>
        <CreateFolder />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $folder_1->as_string, $folder_1_test_string, '->as_string');
