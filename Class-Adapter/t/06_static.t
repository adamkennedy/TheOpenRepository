#!/usr/bin/perl -w

# Main testing for Class::Adapter::Builder

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir(updir(), 'lib') );
	}
}

use Test::More tests => 4;

# Can we use methods statically
ok( Foo::Bar->isa('File::Spec'),        'Positive static isa ok' );
ok( ! Foo::Bar->isa('Something::Else'), 'Negative static isa ok' );
ok( Foo::Bar->can('catfile'),           'Positive static can ok' );
ok( ! Foo::Bar->can('fubared'),         'Negative static can ok' );



#####################################################################
# Testing Package

# This implements a Bubble for a specific class
package Foo::Bar;

use Class::Adapter::Builder
	NEW      => 'File::Spec',
	ISA      => 'File::Spec',
	AUTOLOAD => 1;

1;
