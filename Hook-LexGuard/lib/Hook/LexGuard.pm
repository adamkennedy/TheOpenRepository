package Hook::LexGuard;

use 5.006;
use strict;
use warnings;
use Time::HiRes ();

our $VERSION = '0.01';

sub new {
	my $class   = shift;
	my $handler = shift;
	bless {
		time    => [ Time::HiRes::gettimeofday ],
		handler => $handler,
	}, $class;
}

sub DESTROY {
	$_[0]->{handler}->(
		$_[0]->{time},
		[ Time::HiRes::gettimeofday ],
	);
}

1;
