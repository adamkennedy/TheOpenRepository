#!/usr/bin/perl

use strict;
use CPANDB;
use Mojolicious::Lite;
no warnings;

get '/' => sub {
	my $self = shift;
	$self->render_text(
		$self->param('groovy'),
		layout => 'funky',
	);	
} => 'index';

shagadelic;

__DATA__

@@ layouts/default.html.ep
<!doctype html><html>
	<head><title>Funky!</title></head>
	<body><%== content %></body>
</html>
