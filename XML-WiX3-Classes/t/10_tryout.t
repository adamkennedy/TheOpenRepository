#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

require WiX3::XML::CreateFolder;

plan tests => 6;

my $cf_1 = WiX3::XML::CreateFolder->new();
ok( $cf_1, 'CreateFolder->new returns true' );

my $test2_output = $cf_1->as_string();
my $test2_string = "<CreateFolder />\n";

is( $test2_output, $test2_string, 'Empty CreateFolder stringifies correctly.');

require WiX3::XML::Fragment;

my $frag = WiX3::XML::Fragment->new(id => 'TestID');

ok( $frag, 'Fragment->new returns true' );

my $test4_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_TestID'>

  </Fragment>
</Wix>
EOF

is ($frag->as_string(), $test4_string, 'Empty Fragment stringifies correctly.');

$frag->add_child_tag($cf_1);

my $test5_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_TestID'>
    <CreateFolder />
  </Fragment>
</Wix>
EOF

is ($frag->as_string(), $test5_string, 'Fragment stringifies correctly.');

my $test6_object = {
	child_tags => [ {
		child_tags => [] 
	} ],
	id => 'Fr_TestID'
};

is_deeply ($frag, $test6_object, 'Fragment is deeply correct.');