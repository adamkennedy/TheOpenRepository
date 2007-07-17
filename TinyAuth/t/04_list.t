#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 23;

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
	cgi_cmp( $instance->stdout, <<'END_HTML', '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth 0.04</title>
</head>

<body>
<h2>You don't know your password</h2>
<form method="post" name="f" action="">
<input type="hidden" name="a" value="r"
<p>I can't tell you what your current password is, but I can send you a new one.</p>
<p>&nbsp;</p>
<p>What is your email address? <input type="text" name="e" size="30"> <input type="submit" name="s" value="Email me a new password"></p>
</form>
<p>&nbsp;</p>
<hr>
<p><a href="?a=i">Back to the main page</a></p>

</body>
</html>

END_HTML
}
