#!/usr/bin/perl -w

# Test creation of a ThreatNet::Bot::AmmoBot object

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}





# Does everything load?
use Test::More 'tests' => 6;
use ThreatNet::Bot::AmmoBot;
use POE;





#####################################################################
# Object Creation

my $bot = ThreatNet::Bot::AmmoBot->new(
	Nick    => 'Foo',
	Server  => 'irc.freenode.org',
	Channel => '#threatnettest',
	);
isa_ok( $bot, 'ThreatNet::Bot::AmmoBot' );

# Test the accessors
is( ref($bot->args),  'HASH', '->tails returns a hash' );
is( ref($bot->tails), 'HASH', '->tails returns a hash' );
ok( ! $bot->running, '->running returns false' );
is( scalar($bot->files), 0, '->files returns 0' );

ok( $bot->add_file($0), 'Added file' );

1;

${$poe_kernel->[POE::Kernel::KR_RUN]} |= POE::Kernel::KR_RUN_CALLED;
