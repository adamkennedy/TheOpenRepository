#!/usr/bin/perl

# Testing of a cgi path

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 19;
use Test::File::Cleaner   ();
use File::Spec::Functions ':ALL';
use CGI::Install          ();
use URI::file             ();

my $cleaner = Test::File::Cleaner->new('t');





#####################################################################
# Configuration variables

my $cgi_path = catdir( 't', 'data', 'cgi_path' );
ok( -d $cgi_path, 'The cgi_path exists' );
my $cgi_mock = catdir( 't', 'data', 'cgi_mock' );
ok( -d $cgi_mock, 'The cgi_mock exists' );
my $cgi_uri = URI::file->new( rel2abs( $cgi_mock ) );
isa_ok( $cgi_uri, 'URI::file' );





#####################################################################
# Instantiation

SCOPE: {
	# Create the installation object
	my $cgi = CGI::Install->new(
		interactive    => 0,
		install_cgi    => 1,
		install_static => 0,
		cgi_path    => $cgi_path,
		cgi_uri     => $cgi_uri->as_string,
	);
	isa_ok( $cgi, 'CGI::Install' );

	# Check accessors
	is( $cgi->interactive,    '',        '->interactive ok'    );
	is( $cgi->install_cgi,    1,         '->install_cgi ok'    );
	is( $cgi->install_static, '',        '->install_static ok' );
	is( $cgi->cgi_path,       $cgi_path, '->cgi_path ok'       );
	is( $cgi->cgi_uri,        $cgi_uri,  '->statuc_uri ok'     );
	isa_ok( $cgi->cgi_map, 'URI::ToDisk' );
	is( $cgi->cgi_map->path,  $cgi_path, '->cgi_path ok'       );
	is( $cgi->cgi_map->uri,   $cgi_uri,  '->cgi_uri ok'        );
	is( $cgi->cgi_capture,    undef,     '->cgi_capture undef' );
	is( $cgi->static_path,    undef,     '->static_path undef' );
	is( $cgi->static_uri,     undef,     '->static_uri undef'  );
	is( $cgi->static_map,     undef,     '->static_map undef'  );

	# Validate the static path
	ok( ! -f $cgi->cgi_map->catfile('cgicapture')->path, 'No script before the test' );
	is( $cgi->validate_cgi_dir($cgi->cgi_map), 1, '->validate_cgi_dir ok' );
	ok( ! -f $cgi->cgi_map->catfile('cgicapture')->path, 'No script after the test'  );
}
