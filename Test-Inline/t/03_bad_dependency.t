#!/usr/bin/perl -w

# Specific test for missing dependencies

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 4;
use Test::Inline ();

# Prepare
my $file = File::Spec->catfile( 't', 'data', 'bad_dependency' );

my $PODCONTENT = <<'END_TEST';
# =begin testing foo after bar
{
is( Foo::Bar->foo, 1, '->foo returns expected value' );
}
END_TEST

# Create the Object
my $Inline = Test::Inline->new;
isa_ok( $Inline, 'Test::Inline' );
{
local $Test::Inline::Script::NO_MISSING_DEPENDENCIES_WARNING = 1;
$Test::Inline::Script::NO_MISSING_DEPENDENCIES_WARNING = 1; # Suppress another warning
ok( $Inline->add( $file ), 'Added bad_dependency file ok' );
}
my $Class = $Inline->class('Foo::Bad');
isa_ok( $Class, 'Test::Inline::Script' );
is_deeply( $Class->missing_dependencies, [ 'bar' ], '->missing_dependencies returns expected value' );

1;
