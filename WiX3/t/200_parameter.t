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

plan tests => 5;

WiX3::Traceable->new(tracelevel => 0, testing => 1);
WiX3::XML::GeneratesGUID::Object->new(sitename => 'www.testing.invalid');

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
