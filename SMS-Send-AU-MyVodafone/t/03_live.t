#!/usr/bin/perl -w

# Try to make sure the website is actually there

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

use Test::More tests => 2;
use SMS::Send;

sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Testing an actual working login

my $login    = $ENV{SMS_LOGIN};
my $password = $ENV{SMS_PASSWORD};
my $to       = $ENV{SMS_TO};
my $text     = $ENV{SMS_TEXT} || "Testing SMS::Send::AU::MyVodafone";

SKIP: {
	unless ( $login and $password and $to ) {
		skip("Live testing requires SMS_LOGIN, SMS_PASSWORD and SMS_TO", 2);
	}

	# Create a new sender
	my $sender = SMS::Send->new( 'AU::MyVodafone',
		_login    => $login,
		_password => $password,
		);
	isa_ok( $sender, 'SMS::Send' );

	# Send a real message
	my $rv = $sender->send_sms(
		text => $text,
		to   => $to,
		);
	ok( $rv, '->send_sms sends a live message ok' );
}

exit(0);
