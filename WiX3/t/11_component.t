#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

require WiX3::XML::Component;
require WiX3::Traceable;
require WiX3::XML::GeneratesGUID::Object;

plan tests => 7;

WiX3::Traceable->new(tracelevel => 0, testing => 1);
WiX3::XML::GeneratesGUID::Object->new();

my $cf_1;
eval { $cf_1 = WiX3::XML::Component->new(); };
my $empty_exception = $EVAL_ERROR;

ok( ! $cf_1, 'CreateFolder->new returns false when empty' );
like( 
	$empty_exception, 
	qr{Attribute\s\(id\)}, 
	'CreateFolder->new returns exception that stringifies'
);
isa_ok( $empty_exception, 'WiX3::Exception::Caught', 'Error' );
isa_ok( $empty_exception, 'WiX3::Exception', 'Error' );

my $cf_2 = WiX3::XML::Component->new(id => 'TestID');

ok( ! $cf_1, 'Component->new returns true with id' );
isa_ok( $cf_2, 'WiX3::XML::Component' );
# isa_ok( $empty_exception, 'WiX3::Exception' );

my $test7_output = $cf_2->as_string();
my $test7_string = "<Component Id='C_TestID' Guid='94029F5F-EFBF-39A5-AA11-DC6570C7FF48' />\n";

is( $test7_output, $test7_string, 'Empty Component stringifies correctly.' );

__END__

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

is( $frag->as_string(), $test4_string, 'Empty Fragment stringifies correctly.' );

$frag->add_child_tag($cf_1);

my $test5_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_TestID'>
    <CreateFolder />
  </Fragment>
</Wix>
EOF

is( $frag->as_string(), $test5_string, 'Fragment stringifies correctly.' );

my $test6_object = {
	child_tags => [ {
		child_tags => [] 
	} ],
	id => 'Fr_TestID'
};

is_deeply ($frag, $test6_object, 'Fragment is deeply correct.');


my $stdout = IO::Capture::Stdout->new();
my $stderr = IO::Capture::Stderr->new();

$stdout->start();
$stderr->start();

eval {	my $frag2 = WiX3::XML::Fragment->new(id => 'TestID', idx => 'Test'); }; 

my $exception_object = $EVAL_ERROR;

$stdout->stop();
$stderr->stop();


like($exception_object, qr(constructor: idx), 'Strict constructor creates the correct type of error.');
isa_ok($exception_object, 'WiX3::Exception::Parameter', 'Error' );
isa_ok($exception_object, 'WiX3::Exception', 'Error' );
