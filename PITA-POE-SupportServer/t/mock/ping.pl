#!/usr/bin/perl

use strict;
use HTTP::Tiny ();

HTTP::Tiny->new->get($ARGV[0]);

sleep 1;

exit(0);
