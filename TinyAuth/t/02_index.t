#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;

use File::Spec::Functions ':ALL';
use lib catdir( 't', 'lib' );
use YAML::Tiny;
use My::TinyAuth;
use My::Tests;

# Test files
my $config_file = rel2abs( catfile( 't', 'data', 'tinyauth.yml' ) );
my $cgi_file    = rel2abs( catfile( 't', 'data', '02_index.cgi'  ) );
ok( -f $config_file, 'Testing config file exists' );
ok( -f $cgi_file,    'Testing cgi file exists'    );

# Constructor objects
my $config = YAML::Tiny->new;
$config->[0]->{htpass} = $config_file;
isa_ok( $config, 'YAML::Tiny' );

open( CGIFILE, $cgi_file ) or die "open: $!";
my $cgi = CGI->new(\*CGIFILE);

# Create the object
my $instance = My::TinyAuth->new(
	config => $config,
	cgi    => $cgi,
);
isa_ok( $instance, 'My::TinyAuth' );

# Run the instance
is( $instance->run, 1, '->run ok' );

# Check the output
cgi_cmp( $instance->stdout, <<'END_HTML', '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth 0.03</title>
</head>

<body>
<h2>User</h2>
<p><a href="?a=f">I forgot my password</a></p>
<p><a href="?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="?a=n">I want to add a new account</a></p>
<p><a href="?a=l">I want to see all the accounts</a></p>

</body>
</html>

END_HTML
