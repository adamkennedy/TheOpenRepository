#!/usr/bin/perl

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.05';
}

use Test::More tests => 7;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use t::lib::Test;
use t::lib::TinyAuth;

# Test files
my $cgi_file1 = rel2abs( catfile( 't', 'data', '04_list.cgi'  ) );
ok( -f $cgi_file1, 'Testing cgi file exists' );





#####################################################################
# Show the "I forgot my password" form

SCOPE: {
	open( CGIFILE, $cgi_file1 ) or die "open: $!";
	my $cgi = CGI->new(\*CGIFILE);
	close( CGIFILE );

	# Create the object
	my $instance = t::lib::TinyAuth->new(
		config => default_config(),
		cgi    => $cgi,
	);
	isa_ok( $instance, 't::lib::TinyAuth' );
	isa_ok( $instance, 'TinyAuth' );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h2>Account List</h2>
adamk\@cpan.org<br />

</body>
</html>

END_HTML
}
