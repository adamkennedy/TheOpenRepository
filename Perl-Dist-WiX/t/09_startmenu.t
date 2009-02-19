#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::StartMenu;
require Perl::Dist::WiX::StartMenuComponent;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 18;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $menu_1 = Perl::Dist::WiX::StartMenu->new(
    sitename  => 'ttt.test.invalid',
);

ok( defined $menu_1, 'creating a P::D::W::StartMenu' );

isa_ok( $menu_1, 'Perl::Dist::WiX::StartMenu', 'The start menu');
isa_ok( $menu_1, 'Perl::Dist::WiX::Base::Fragment', 'The start menu');

is( $menu_1->as_string, q{}, 'StartMenu->as_string with no component');
is_deeply( $menu_1->get_component_array, 'RemoveShortcutFolder', 'StartMenu->get_component_array with no component');

my $component_1 = Perl::Dist::WiX::StartMenuComponent->new(
    sitename    => 'ttt.test.invalid',
    id          => 'Test_Icon',
    name        => 'Test Icon',
    description => 'Test Icon Entry',
    target      => '[D_TestDir]file.test',
    working_dir => 'TestDir',
    menudir_id  => 'D_App_Menu',
    icon_id     => 'icon.test',
    trace       => 100,
);

ok( defined $component_1, 'creating a P::D::W::StartMenuComponent' );

isa_ok( $component_1, 'Perl::Dist::WiX::StartMenuComponent', 'The start menu component');
isa_ok( $component_1, 'Perl::Dist::WiX::Base::Component', 'The start menu component');
isa_ok( $component_1, 'Perl::Dist::WiX::Misc', 'The start menu component');

eval {
    my $component_3 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => undef,
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(Missing or invalid id), 'StartMenuComponent->new catches bad id' );

eval {
    my $component_4 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => undef,
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(Missing or invalid name), 'StartMenuComponent->new catches bad name' );

eval {
    my $component_5 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => undef,
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(Missing or invalid target), 'StartMenuComponent->new catches bad target' );

eval {
    my $component_6 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => undef,
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(Missing or invalid working_dir), 'StartMenuComponent->new catches bad working_dir' );

eval {
    my $component_7 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => undef,
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(Missing or invalid menudir_id), 'StartMenuComponent->new catches bad menudir_id' );

eval {
    my $component_8 = Perl::Dist::WiX::StartMenuComponent->new(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => undef,
        trace       => 100,
    );
};

like($@, qr(Missing or invalid icon_id), 'StartMenuComponent->new catches bad icon_id' );

my $component_test_string_1 = <<'EOF';
<Component Id='C_S_Test_Icon' Guid='7F231660-EE9D-34A7-AC48-DD3A45C7235C'>
  <Shortcut Id='S_Test_Icon'
            Name='Test Icon'
            Description='Test Icon Entry'
            Target='[D_TestDir]file.test'
            Icon='I_icon.test'
            WorkingDirectory='D_TestDir' />
  <CreateFolder Directory="D_App_Menu" />
</Component>
EOF

is( $component_1->as_string, $component_test_string_1, 'StartMenuComponent->as_string');

$menu_1->add_component($component_1);

my $menu_test_string_1 = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Icons'>
    <DirectoryRef Id='ApplicationProgramsFolder'>
      <Component Id='C_S_Test_Icon' Guid='7F231660-EE9D-34A7-AC48-DD3A45C7235C'>
        <Shortcut Id='S_Test_Icon'
                  Name='Test Icon'
                  Description='Test Icon Entry'
                  Target='[D_TestDir]file.test'
                  Icon='I_icon.test'
                  WorkingDirectory='D_TestDir' />
        <CreateFolder Directory="D_App_Menu" />
      </Component>
      <Component Id='C_RemoveShortcutFolder' Guid='F873BBBD-E8ED-3D6D-9D28-B42BD4EE457B'>
        <RemoveFolder Id="ApplicationProgramsFolder" On="uninstall" />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

my @array = $menu_1->get_component_array;

is( $menu_1->as_string, $menu_test_string_1, 'StartMenu->as_string');
is_deeply( \@array, ['RemoveShortcutFolder', 'S_Test_Icon'], 'StartMenu->get_component_array');
