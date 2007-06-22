#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use File::Spec::Functions ':ALL';
use lib catdir( 't', 'lib' );
use YAML::Tiny;
use My::TinyAuth;

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
my $page = <<'END_HTML';
Content-Type: text/html; charset=ISO-8859-1

<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>TinyAuth 0.01</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>
<p>Hello World!</p>
</body>
</html>
END_HTML

chomp($page);
is( $instance->stdout, $page, '->stdout returns as expect' );
