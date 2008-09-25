#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use Test::SubCalls;
use File::Spec::Functions       ':ALL';
use File::Temp                  ();
use Template                    ();
use Template::Provider          ();
use Template::Provider::Preload ();

my $INCLUDE_PATH = [
	catdir( 't', 'template' ),
	catdir( 't', 'template2' ),
];
ok( -d $INCLUDE_PATH->[0], 'Found template directory 1' );
ok( -d $INCLUDE_PATH->[1], 'Found template directory 2' );

# Create the preloader
my $provider = Template::Provider::Preload->new(
	PRECACHE     => 1,
        INCLUDE_PATH => $INCLUDE_PATH,
);
isa_ok( $provider, 'Template::Provider' );

# Can we get the transformed paths
is_deeply( $provider->paths, $INCLUDE_PATH, '->paths ok' );

# Fetch a compiled template directly
sub_track( 'Template::Provider::fetch' );
ok( $provider->prefetch, '->prefetch returns true' );
sub_calls( 'Template::Provider::fetch', 7, 'Initial fetches called' );

# Create a Template processor
my $template = Template->new(
	DEBUG          => 1,
	LOAD_TEMPLATES => [ $provider ],
);
isa_ok( $template, 'Template' );

# Do a template run
my $output = '';
sub_reset( 'Template::Provider::fetch' );
$template->process('four.tt', { name => 'Ingy' }, \$output )
	or do {
		die $template->error;
	};
is( $output, "Hello, Ingy.\n", "output is correct" );
sub_calls( 'Template::Provider::fetch', 0, 'Provider fetch not called' );
