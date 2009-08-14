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

plan tests => 13;

WiX3::Traceable->new(tracelevel => 0, testing => 1);
WiX3::XML::GeneratesGUID::Object->new(sitename => 'www.testing.invalid');

my $c_1;
eval { $c_1 = WiX3::XML::Component->new(); };
my $empty_exception = $EVAL_ERROR;

ok( ! $c_1, 'CreateFolder->new returns false when empty' );
like( 
	$empty_exception, 
	qr{Attribute\s\(id\)}, 
	'CreateFolder->new returns exception that stringifies'
);
isa_ok( $empty_exception, 'WiX3::Exception::Caught', 'Error' );
isa_ok( $empty_exception, 'WiX3::Exception', 'Error' );

my $c_2 = WiX3::XML::Component->new(id => 'TestID');

ok( $c_2, 'Component->new returns true with id' );
isa_ok( $c_2, 'WiX3::XML::Component' );

my $test7_output = $c_2->as_string();
my $test7_string = "<Component Id='C_TestID' Guid='94029F5F-EFBF-39A5-AA11-DC6570C7FF48' />\n";

is( $test7_output, $test7_string, 'Empty Component stringifies correctly.' );

require WiX3::XML::CreateFolder;

my $cf_1 = WiX3::XML::CreateFolder->new();
$c_2->add_child_tag($cf_1);

my $test8_output = $c_2->as_string();
my $test8_string = <<'EOF';
<Component Id='C_TestID' Guid='94029F5F-EFBF-39A5-AA11-DC6570C7FF48'>
  <CreateFolder />
<Component />
EOF

is( $test8_output, $test8_string, 'Non-empty Component stringifies correctly.' );

my $c_3;
eval { $c_3 = WiX3::XML::Component->new(id => 'TestBad', diskid => 'TestBad'); };
my $empty_exception = $EVAL_ERROR;

ok( ! $c_3, 'CreateFolder->new returns false when bad parameter passed in' );
like( 
	$empty_exception, 
	qr{pass the type constraint}, 
	'CreateFolder->new returns exception that stringifies'
);
isa_ok( $empty_exception, 'WiX3::Exception::Parameter::Validation', 'Error' );
isa_ok( $empty_exception, 'WiX3::Exception::Parameter', 'Error' );
isa_ok( $empty_exception, 'WiX3::Exception', 'Error' );
