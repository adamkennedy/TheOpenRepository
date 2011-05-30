package EVE::Config;

use 5.008;
use strict;
use warnings;
use Config::Tiny ();

our $VERSION = '0.01';
our @ISA     = 'Config::Tiny';

sub exe {
	$_[0]->{_}->{exe};
}

sub userid {
	$_[0]->{_}->{userid};
}

sub username {
	$_[0]->{_}->{username};
}

sub password {
	$_[0]->{_}->{password};
}

sub api_limited {
	$_[0]->{_}->{api_limited};
}

sub api_full {
	$_[0]->{_}->{api_full};
}

1;
