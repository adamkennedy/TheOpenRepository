package EVE::Shell;

use strict;
use warnings;
use Class::Inspector ();
use EVE::Game        ();

our $VERSION = '0.01';

# Autostart if not called as "use EVE::Shell ();"
sub import {
	$_[0]->start;
}

sub start {
	my $class = shift;
	print "Connecting to EVE... ";
	$main::game = EVE::Game->new(@_);
	$main::game->attach;
	$main::game->connect;
	print "CONNECTED\n";
}

BEGIN {
	my $functions = Class::Inspector->functions('EVE::Game');
	local $@;
	eval join "\n\n", map {
		"sub main::$_ {\n\t\$main::game->$_(\@_);\n}\n"
	} @$functions;
	die $@ if $@;
}

1;
