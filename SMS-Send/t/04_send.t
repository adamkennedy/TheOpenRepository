#!/usr/bin/perl -w

# Test the sending of a message

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 4;
use SMS::Send;

use Params::Util '_INSTANCE';
sub dies_like {
	my $code   = shift;
	my $regexp = _INSTANCE(shift, 'Regexp')
		or die "Did not provide regexp to dies_like";
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Good Send

# Create a new test sender
SCOPE: {
	my $sender1 = SMS::Send->new( 'Test' );
	isa_ok( $sender1, 'SMS::Send' );
	is( $sender1->clear, 1, 'Methods pass through to the driver' );

	# Send the message
	my $rv = $sender1->send_sms(
		text     => 'This is a test',
		to       => '+61 (4) 1234 5678',
		ignore   => 'asdf',
		_private => 'value',
		);
	is( $rv, 1, '->send_sms returns true' );

	# Get the sent message
	my @messages = $sender1->messages;
	is_deeply( \@messages, [ [
		text     => 'This is a test',
		to       => '+61412345678',
		_private => 'value',
		] ], 'Message gets send as expected' );
}





#####################################################################
# Bad Creation

# To be completed

exit(0);
