#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 19;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

require Perl::Dist::WiX::Environment;
require Perl::Dist::WiX::EnvironmentEntry;

#####################################################################
#

my $env_1 = Perl::Dist::WiX::Environment->new(
    sitename => 'www.test.site.invalid',
);
ok( $env_1, 'Environment->new returns true' );

my $entry_1 = Perl::Dist::WiX::EnvironmentEntry->new(
    id    => 'TestEnv_1',
    name  => 'Random',
    value => 'Number',
);
ok( $entry_1, 'EnvironmentEntry->new returns true' );

eval {
    my $env_2 = Perl::Dist::WiX::Environment->new(
        sitename => undef,
    );
};

like($@, qr(Missing or invalid sitename), 'Environment->new catches bad sitename' );

eval {
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => undef,
        name  => 'Random',
        value => 'Number',
    );
};

like($@, qr(Missing or invalid id), 'EnvironmentEntry->new catches bad id' );

eval {
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => 'TestEnv_1',
        name  => undef,
        value => 'Number',
    );
};

like($@, qr(Missing or invalid name), 'EnvironmentEntry->new catches bad name' );

eval {
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => 'TestEnv_1',
        name  => 'Random',
        value => undef,
    );
};

like($@, qr(Missing or invalid value), 'EnvironmentEntry->new catches bad value' );

my $env_test_1 = bless( {
  'sitename' => 'www.test.site.invalid',
  'entries' => [],
  'components' => [],
  'guid' => '4CE58C80-E259-34EF-B47E-B1C8299D320A',
  'id' => 'Environment',
  'directory' => 'TARGETDIR'
}, 'Perl::Dist::WiX::Environment' );

is_deeply( $env_1, $env_test_1, 'Environment object created correctly' );

my $entry_test_1 = bless( {
  'permanent' => 'no',
  'value' => 'Number',
  'part' => 'all',
  'action' => 'set',
  'name' => 'Random',
  'id' => 'TestEnv_1'
}, 'Perl::Dist::WiX::EnvironmentEntry' );

is_deeply( $entry_1, $entry_test_1, 'EnvironmentEntry object created correctly' );

isa_ok( $env_1, 'Perl::Dist::WiX::Environment' );
isa_ok( $env_1, 'Perl::Dist::WiX::Base::Fragment' );
isa_ok( $env_1, 'Perl::Dist::WiX::Base::Component' );
isa_ok( $entry_1, 'Perl::Dist::WiX::EnvironmentEntry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Base::Entry' );

is( $env_1->get_component_array, 'Environment', 'Environment->get_component_array' );

my $environment_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Environment'>
    <DirectoryRef Id='TARGETDIR'>
      <Component Id='C_Environment' Guid='4CE58C80-E259-34EF-B47E-B1C8299D320A'>
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $env_1->as_string, $environment_string, 'Environment->as_string' );

my $entry_string = <<'EOF';
   <Environment Id='E_TestEnv_1' Name='Random' Value='Number' 
      System='yes' Permanent='no' Action='set' Part='all' />
EOF

is( $entry_1->as_string, $entry_string, 'EnvironmentEntry->as_string' );

## TODO: 

$env_1->add_entry(
    id    => 'TestEnv_2',
    name  => 'Psuedo',
    value => 'Random',
);

ok ( exists $env_1->{entries}->[0], 'Environment->add_entry adds entry that exists');
isa_ok( $env_1->{entries}->[0], 'Perl::Dist::WiX::EnvironmentEntry' , 'Environment->add_entry adds EnvironmentEntry');


my $entry_string_2 = <<'EOF';
   <Environment Id='E_TestEnv_2' Name='Psuedo' Value='Random' 
      System='yes' Permanent='no' Action='set' Part='all' />
EOF

is( $env_1->{entries}->[0]->as_string, $entry_string_2, 'Environment->add_entry adds correct entry' );
