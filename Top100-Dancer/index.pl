#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Dancer;
use Template;

# Configuration block
set template => 'template_toolkit';
set engines  => {
    template_toolkit => {
        start_tag => '[%',
        stop_tag  => '%]',
    },
};

# Route block
get '/' => sub {
    template 'index';
};

dance;
