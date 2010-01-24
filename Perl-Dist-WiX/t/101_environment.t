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

require Perl::Dist::WiX::Fragment::Environment;
require Perl::Dist::WiX::DirectoryTree2;

#####################################################################
#

my $tree = Perl::Dist::WiX::DirectoryTree2->new(app_dir => '.', app_name => 'test', trace => 0);

my $env_1 = Perl::Dist::WiX::Fragment::Environment->new(
    sitename => 'www.test.site.invalid',
);
ok( $env_1, 'Environment->new returns true' );

my $test_empty = <<'END_OF_STRING';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Environment'>
    <DirectoryRef Id='TARGETDIR'>
      <Component Id='C_Environment' Guid='32B594CC-E044-3A3D-A027-670D9F4299B4' />
    </DirectoryRef>
  </Fragment>
</Wix>
END_OF_STRING

is( $env_1->as_string(), $test_empty, 'Environment->as_string with no entries' );

my $entry_1 = $env_1->add_entry(
    id    => 'TestEnv_1',
    name  => 'Random',
    value => 'Number',
);
ok( $entry_1, 'Environment->add_entry returns true' );

eval {
    my $entry_2 = $env_1->add_entry(
        id    => undef,
        name  => 'Random',
        value => 'Number',
    );
};

like($@, qr('id' not Str), 'Environment->add_entry catches bad id' );

eval {
    my $entry_2 = $env_1->add_entry(
        id    => 'TestEnv_1',
        name  => undef,
        value => 'Number',
    );
};

like($@, qr('name' not Str), 'Environment->add_entry catches bad name' );

eval {
    my $entry_2 = $env_1->add_entry(
        id    => 'TestEnv_1',
        name  => 'Random',
        value => undef,
    );
};

like($@, qr('value' not Str), 'Environment->add_entry catches bad value' );

isa_ok( $env_1, 'Perl::Dist::WiX::Fragment::Environment' );
isa_ok( $env_1, 'WiX3::XML::Fragment' );

$env_1->add_entry(
    id    => 'TestEnv_2',
    name  => 'Psuedo',
    value => 'Random',
);

is( $env_1->get_entries_count(), 2, 'Environment->add_entry adds entry successfully');

my $environment_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Environment'>
    <DirectoryRef Id='TARGETDIR'>
      <Component Id='C_Environment' Guid='32B594CC-E044-3A3D-A027-670D9F4299B4'>
        <Environment Id='E_TestEnv_1' Name='Random' Value='Number' System='yes' Permanent='yes' Action='set' Part='all' />
        <Environment Id='E_TestEnv_2' Name='Psuedo' Value='Random' System='yes' Permanent='yes' Action='set' Part='all' />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $env_1->as_string, $environment_string, 'Environment->as_string' );
