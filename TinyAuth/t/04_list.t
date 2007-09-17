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





#####################################################################
# Show the "I forgot my password" form

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "04_list.cgi" );

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
