#!/usr/bin/perl

# Compile-testing for Process

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'Process'                 );
	use_ok( 'Process::Infinite'       );
	use_ok( 'Process::Serializable'   );
	use_ok( 'Process::Storable'       );
	use_ok( 'Process::Delegatable'    );
	use_ok( 'Process::Launcher'       );
}

is( $Process::VERSION, $Process::Infinite::VERSION,       '::Process == ::Infinite'       );
is( $Process::VERSION, $Process::Serializable::VERSION,   '::Process == ::Serializable'   );
is( $Process::VERSION, $Process::Storable::VERSION,       '::Process == ::Storable'       );
is( $Process::VERSION, $Process::Launcher::VERSION,       '::Process == ::Launcher'       );
is( $Process::VERSION, $Process::Delegatable::VERSION,    '::Process == ::Delegatable'    );

# Does the launcher export the appropriate things
ok( defined(&run),        'Process::Launcher exports &run'        );
ok( defined(&run3),       'Process::Launcher exports &run3'       );
ok( defined(&serialized), 'Process::Launcher exports &serialized' );

# Include the testing modules
use_ok( 'MySimpleProcess'      );
use_ok( 'MyStorableProcess'    );
use_ok( 'MyDelegatableProcess' );

exit(0);
