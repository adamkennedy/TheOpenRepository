#!/usr/bin/perl

use strict;
use warnings;
use Dancer;

get '/' => sub {
    return "Hello World!"
};

dance;
