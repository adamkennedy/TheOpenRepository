#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use CGI::Install ();
use URI::file    ();

my $cgi_path = catdir( 't', 'data', 'cgidir' );
ok( -d $cgi_path, 'The cgidir exists' );





#####################################################################
# Instantiation

SCOPE: {
	my $cgi = CGI::Install->new(
		interactive => 0,
		cgi_path    => $cgi_path,
	);
	isa_ok( $cgi, 'CGI::Install' );
}
