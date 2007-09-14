#!/usr/bin/perl

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.07';
}

use Test::More tests => 7;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use t::lib::Test;
use t::lib::TinyAuth;

# Test files
my $cgi_file = rel2abs( catfile( 't', 'data', '08_login.cgi'  ) );
ok( -f $cgi_file, 'Testing cgi file exists' );

open( CGIFILE, $cgi_file ) or die "open: $!";
my $cgi = CGI->new(\*CGIFILE);

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
<h2>User</h2>
<p><a href="?a=f">I forgot my password</a></p>
<p><a href="?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="?a=n">I want to add a new account</a></p>
<p><a href="?a=l">I want to see all the accounts</a></p>
<p><a href="?a=d">I want to delete an account</a></p>
<p><a href="?a=m">I want to promote an account to admin</a></p>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>

END_HTML
