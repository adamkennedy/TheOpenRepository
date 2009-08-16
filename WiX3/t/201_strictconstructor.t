#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	use IO::Capture::Stdout;
	use IO::Capture::Stderr;
	$OUTPUT_AUTOFLUSH = 1;
}

require WiX3::Traceable;
require WiX3::XML::Fragment;

plan tests => 3;

WiX3::Traceable->new(tracelevel => 0, testing => 1);

eval {	my $frag2 = WiX3::XML::Fragment->new(id => 'TestID', idx => 'Test'); }; 
my $exception_object = $EVAL_ERROR;

like($exception_object, qr(constructor: idx), 'Strict constructor creates the correct type of error.');
isa_ok($exception_object, 'WiX3::Exception::Parameter', 'Error' );
isa_ok($exception_object, 'WiX3::Exception', 'Error' );
