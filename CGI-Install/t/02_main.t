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

my $cgidir = catdir( 't', 'data', 'cgidir' );
ok( -d $cgidir, 'The cgidir exists' );





#####################################################################
# Instantiation

SCOPE: {
	my $cgi = CGI::Install->new(
		
}
