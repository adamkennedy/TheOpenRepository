#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::Registry;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 22;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $registry_1 = Perl::Dist::WiX::Registry->new(
    sitename  => 'ttt.test.invalid',
);

ok( defined $registry_1, 'creating a P::D::W::Registry' );

isa_ok( $registry_1, 'Perl::Dist::WiX::Registry');
isa_ok( $registry_1, 'Perl::Dist::WiX::Base::Fragment');

eval {
    my $registry_2 = Perl::Dist::WiX::Registry->new(
        sitename  => undef,
    );
};

like($@, qr(Missing or invalid sitename), 'Registry->new catches bad sitename' );

is ( $registry_1->as_string, q{}, '->as_string with no keys');
is ( $registry_1->get_component_array, undef, '->get_component_array with no keys');

$registry_1->add_key(
    key        => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    id         => 'RegistryKey2',
    name       => 'TEST', 
    value      => 'test string', 
    action     => 'test', 
    value_type => 'expandable',
);

my $registry_test_1 = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Registry'>
    <DirectoryRef Id='TARGETDIR'>
      <Component Id='C_RegistryKey2' Guid='91FB6C32-AB34-3A58-B6E8-889409BC240A'>
        <RegistryKey Root='HKLM' Key='SYSTEM\CurrentControlSet\Control\Session Manager\Environment'>
          <RegistryValue Action='test' Type='expandable' Name='TEST' Value='test string' />
        </RegistryKey>
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is ( $registry_1->as_string, $registry_test_1, '->as_string');
is_deeply ( $registry_1->get_component_array, 'C_RegistryKey2', '->get_component_array');

my $key_1 = Perl::Dist::WiX::Registry::Key->new(
    sitename  => 'ttt.test.invalid',
    key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    id        => 'RegistryKey',
);

ok( defined $key_1, 
    'creating a P::D::W::Registry::Key' );

isa_ok( $key_1, 'Perl::Dist::WiX::Registry::Key');
isa_ok( $key_1, 'Perl::Dist::WiX::Base::Component');

eval {
    my $key_2 = Perl::Dist::WiX::Registry::Key->new(
        sitename  => undef,
        key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        id        => 'RegistryKey',
    );
};

like($@, qr(Missing or invalid sitename), 'Registry::Key->new catches bad sitename' );

eval {
    my $key_3 = Perl::Dist::WiX::Registry::Key->new(
        sitename  => 'ttt.test.invalid',
        key       => undef,
        id        => 'RegistryKey',
    );
};

like($@, qr(Missing or invalid subkey), 'Registry::Key->new catches bad key' );

eval {
    my $key_4 = Perl::Dist::WiX::Registry::Key->new(
        sitename  => 'ttt.test.invalid',
        key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        id        => undef,
    );
};

like($@, qr(Missing or invalid id), 'Registry::Key->new catches bad id' );

is( $key_1->as_string,
    q{},
    '->as_string with no entries');

    
$key_1->add_registry_entry('TEST', 'test string', 'test', 'expandable');

my $expected = <<'END_OF_TEXT';
<Component Id='C_RegistryKey' Guid='F33F64CA-1750-3AEF-BB3A-BCDFE1D4C3AC'>
  <RegistryKey Root='HKLM' Key='SYSTEM\CurrentControlSet\Control\Session Manager\Environment'>
    <RegistryValue Action='test' Type='expandable' Name='TEST' Value='test string' />
  </RegistryKey>
</Component>
END_OF_TEXT
    
is( $key_1->as_string,
    $expected,
    'adding a P::D::W::Registry::Entry' );

is( $key_1->is_key('HKLM', 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment')  ,
    1,
    'Testing existence of an entry' );
    
is( $key_1->is_key('HKCU', 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment')  ,
    0,
    'Testing non-existence of an entry' );

eval {
    my $entry_1 = Perl::Dist::WiX::Registry::Entry->new(
        action     => undef,
        value_type => 'expandable',
        value_name => 'test string',
        value_data => 'test', 
    );
};

like($@, qr(Missing or invalid action), 'Registry::Entry->new catches bad action' );

eval {
    my $entry_2 = Perl::Dist::WiX::Registry::Entry->new(
        action     => 'TEST',
        value_type => '***expable',
        value_name => 'test string',
        value_data => 'test', 
    );
};

like($@, qr(Invalid value_type), 'Registry::Entry->new catches bad value_type' );

eval {
    my $entry_3 = Perl::Dist::WiX::Registry::Entry->new(
        action     => 'TEST',
        value_type => 'expandable',
        value_name => undef,
        value_data => 'test', 
    );
};

like($@, qr(Missing or invalid value_name), 'Registry::Entry->new catches bad value_name' );

eval {
    my $entry_4 = Perl::Dist::WiX::Registry::Entry->new(
        action     => 'TEST',
        value_type => 'expandable',
        value_name => 'teststring',
        value_data => undef, 
    );
};

like($@, qr(Missing or invalid value_data), 'Registry::Entry->new catches bad value_data' );

