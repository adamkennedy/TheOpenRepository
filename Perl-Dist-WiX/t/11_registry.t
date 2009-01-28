#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Perl::Dist::WiX::Registry::Key;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 7;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $key_1 = Perl::Dist::WiX::Registry::Key->new(
    sitename  => 'ttt.test.invalid',
    key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    id        => 'Registry',
);

ok( defined $key_1, 
    'creating a P::D::W::Registry::Key' );

isa_ok( $key_1, 'Perl::Dist::WiX::Registry::Key');
isa_ok( $key_1, 'Perl::Dist::WiX::Base::Component');

is( $key_1->as_string,
    q{},
    'testing as_string with empty key');

    
$key_1->add_registry_entry('TEST', 'test string', 'test', 'expandable');

my $expected = <<'END_OF_TEXT';
<Component Id='C_Registry' Guid='D057906F-D6B1-3831-9E35-79B0334C9E88'>
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

#my $key_2 = Perl::Dist::WiX::Registry::Key->add_environment(
#    sitename  => 'ttt.test.invalid',
#);    
