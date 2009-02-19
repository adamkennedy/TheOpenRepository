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
require Data::UUID;

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
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => undef,
        name  => 'Random',
        value => 'Number',
    );
};

like($@, qr(Missing mandatory initializer 'id'), 'EnvironmentEntry->new catches bad id' );

eval {
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => 'TestEnv_1',
        name  => undef,
        value => 'Number',
    );
};

like($@, qr(Missing mandatory initializer 'name'), 'EnvironmentEntry->new catches bad name' );

eval {
    my $entry_2 = Perl::Dist::WiX::EnvironmentEntry->new(
        id    => 'TestEnv_1',
        name  => 'Random',
        value => undef,
    );
};

like($@, qr(Missing mandatory initializer 'value'), 'EnvironmentEntry->new catches bad value' );

my $env_test_1 = [
  'Perl::Dist::WiX::Environment',
  {
    'Perl::Dist::WiX::Base::Component' => {
                                            'entries' => [],
                                            'id' => 'Environment',
                                            'guid' => '4CE58C80-E259-34EF-B47E-B1C8299D320A'
                                          },
    'Perl::Dist::WiX::Base::Fragment' => {
                                           'components' => [],
                                           'id' => 'Environment',
                                           'directory' => 'TARGETDIR'
                                         },
    'Perl::Dist::WiX::Misc' => {
                                 'sitename' => 'www.test.site.invalid',
                                 'trace' => 0,
                                 'siteguid' => Data::UUID->new()->from_string('0F8DF6BA-27B4-3F6E-9EE0-21B0C963B334')
                               }
  }
];

is_deeply( $env_1->dump(), $env_test_1, 'Environment object created correctly' );

my $entry_test_1 = [
  'Perl::Dist::WiX::EnvironmentEntry',
  {
    'Perl::Dist::WiX::EnvironmentEntry' => {
                                             'value' => 'Number',
                                             'permanent' => 'no',
                                             'name' => 'Random',
                                             'action' => 'set',
                                             'part' => 'all',
                                             'id' => 'TestEnv_1'
                                           },
    'Perl::Dist::WiX::Misc' => {
                                 'sitename' => 'www.test.site.invalid',
                                 'trace' => 0,
                                 'siteguid' => Data::UUID->new()->from_string('0F8DF6BA-27B4-3F6E-9EE0-21B0C963B334')
                               }
  }
];

is_deeply( $entry_1->dump(), $entry_test_1, 'EnvironmentEntry object created correctly' );

isa_ok( $env_1, 'Perl::Dist::WiX::Environment' );
isa_ok( $env_1, 'Perl::Dist::WiX::Base::Fragment' );
isa_ok( $env_1, 'Perl::Dist::WiX::Base::Component' );
isa_ok( $env_1, 'Perl::Dist::WiX::Misc' );

isa_ok( $entry_1, 'Perl::Dist::WiX::EnvironmentEntry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Base::Entry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Misc' );

is( $env_1->get_component_array, 'Environment', 'Environment->get_component_array' );

is( $env_1->as_string, q{}, 'Environment->as_string with no entries' );

my $entry_string = <<'EOF';
   <Environment Id='E_TestEnv_1' Name='Random' Value='Number'
      System='yes' Permanent='no' Action='set' Part='all' />
EOF

is( $entry_1->as_string, $entry_string, 'EnvironmentEntry->as_string' );

$env_1->add_entry(
    id    => 'TestEnv_2',
    name  => 'Psuedo',
    value => 'Random',
);

is( $env_1->get_entries_count, 1, 'Environment->add_entry adds entry successfully');

my $environment_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Environment'>
    <DirectoryRef Id='TARGETDIR'>
      <Component Id='C_Environment' Guid='4CE58C80-E259-34EF-B47E-B1C8299D320A'>
         <Environment Id='E_TestEnv_2' Name='Psuedo' Value='Random'
            System='yes' Permanent='no' Action='set' Part='all' />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $env_1->as_string, $environment_string, 'Environment->as_string' );
