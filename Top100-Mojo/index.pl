#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB {
	maxage => 3600 * 24 * 7,
};
use Mojolicious::Lite;
no warnings;

get '/' => sub {
	my $self = shift;
	$self->render('index');
} => 'index';

shagadelic;
