#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Dancer;
use Template;
use CPANDB;





######################################################################
# Configuration block

set log      => 'core';
set logger   => 'console';
set template => 'template_toolkit';
set engines  => {
	template_toolkit => {
		start_tag => '[%',
		stop_tag  => '%]',
	},
};





######################################################################
# Route block

get '/' => sub {
	template 'index';
};

get '/graph' => sub {
	return render_graph(
		name    => params->{name},
		rankdir => 1,
	);
};

dance;





######################################################################
# Support Functions

sub render_graph {
	my %param = @_;
	my $name  = delete $param{name};
	my $dist  = CPANDB->distribution($name);
	content_type('image/svg+xml');
	return $dist->dependency_graphviz(%param)->as_svg;
}
