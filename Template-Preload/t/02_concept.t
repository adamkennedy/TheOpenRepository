#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use File::Temp            ();
use Template              ();
use Template::Provider::Preload     ();
use Class::Adapter::Clear ();

my $INCLUDE_PATH = catdir( 't', 'template' );
my $COMPILE_DIR  = File::Temp::tempdir( CLEANUP => 1 );
ok( -d $INCLUDE_PATH, 'Found template directory' );
ok( -d $COMPILE_DIR,  'Found compile directory'  );

# Create the preloader
my $provider = Template::Provider::Preload->new(
	DEBUG        => 1,
	NOSTAT       => 1,
        INCLUDE_PATH => $INCLUDE_PATH,
        COMPILE_DIR  => $COMPILE_DIR,
);
isa_ok( $provider, 'Template::Provider' );

# Can we get the transformed paths
is_deeply( $provider->paths, [ $INCLUDE_PATH ], '->paths ok' );

# Fetch a compiled template directly
$provider->preload;
$provider->prefetch;

# Test the provider subclass
test_provider( $provider );

# Create the adapter
my $adapter = Class::Adapter::Clear->new( $provider );
isa_ok( $adapter, 'Template::Provider' );
test_provider( $adapter );

sub test_provider {
	my $p = shift;

	# Create a Template processor
	my $template = Template->new(
		DEBUG          => 1,
		LOAD_TEMPLATES => [ $provider ],
	);
	isa_ok( $template, 'Template' );

	# Do a template run
	my $output = '';
	$template->process('a/b/c/hello.tt', { name => 'Ingy' }, \$output )
		or do {
			die $template->error;
		};
	is( $output, "Hello, Ingy.\n", "output is correct" );
}

1;
