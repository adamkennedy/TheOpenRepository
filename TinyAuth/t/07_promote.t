#!/usr/bin/perl

# Test promotion to administrator

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.91';
}

use Test::More tests => 34;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use Email::Send::Test;
use t::lib::Test;
use t::lib::TinyAuth;





#####################################################################
# Try to the actions as a (forbidden) regular user

SCOPE: {
	my $instance = t::lib::TinyAuth->new(  "07_promote1.cgi" );

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
<h1>Error</h1>
<h2>Only administrators are allowed to do that</h2>
</body>
</html>

END_HTML
}

SCOPE: {
	my $instance = t::lib::TinyAuth->new(  "07_promote2.cgi" );

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
<h1>Error</h1>
<h2>Only administrators are allowed to do that</h2>
</body>
</html>

END_HTML
}









#####################################################################
# Show the "I forgot my password" form

SCOPE: {
	$ENV{HTTP_COOKIE} = 'e=adamk@cpan.org;p=foo';
	my $instance = t::lib::TinyAuth->new( "07_promote1.cgi" );

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
<h2>Select Accounts to Promote</h2>
<form name="f" action="">
<b><label><input type="checkbox" name="_" value="adamk\@cpan.org" disabled />adamk\@cpan.org</label></b><br />
<label><input type="checkbox" name="e" value="foo\@bar.com" />foo\@bar.com</label><br />

<input type="hidden" name="a" value="m">
<input type="submit" name="s" value="Promote">
</form>
</body>
</html>

END_HTML
}





#####################################################################
# Request a bad password

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "07_promote2.cgi" );

	# Run the instance
	Email::Send::Test->clear;
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
<h1>Action Completed</h1>
<h2>Promoted account foo\@bar.com to admin</h2>
</body>
</html>

END_HTML

	# Look for a test email
	my @mails = Email::Send::Test->emails;
	is( scalar(@mails), 1, 'Found 1 email' );
	isa_ok( $mails[0], 'Email::Simple' );
}
