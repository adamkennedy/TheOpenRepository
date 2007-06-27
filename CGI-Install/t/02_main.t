#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use CGI::Install ();
use URI::file    ();





#####################################################################
# Instantiation

# Test the null case
SCOPE: {
	my $cgi = CGI::Install->new(
		interactive    => 0,
		install_static => 0,
		static_uri     => 'foo',
		static_path    => 'foo',		
		install_cgi    => 0,
		cgi_uri        => 'foo',
		cgi_path       => 'foo',
	);
	isa_ok( $cgi, 'CGI::Install' );
	is( $cgi->interactive,    '',    '->interactive ok'    );
	is( $cgi->install_static, '',    '->install_static ok' );
	is( $cgi->install_cgi,    '',    '->install_cgi ok'    );
	is( $cgi->static_uri,     undef, '->static_uri ok'     );
	is( $cgi->static_path,    undef, '->static_path ok'    );
	is( $cgi->cgi_uri,        undef, '->cgi_uri ok'        );
	is( $cgi->cgi_path,       undef, '->cgi_path ok'       );

	# Test support files
	ok(   $cgi->_module_exists('CGI::Capture'), '->_module_exists(good) ok' );
	ok( ! $cgi->_module_exists('My::FooBar'),   '->_module_exists(bad) ok'  );
}
