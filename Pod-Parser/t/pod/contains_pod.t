#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id$

use strict;
use lib qw( ./lib );

use Test::More tests => 1;

use Pod::Find qw( contains_pod );

{
    ok(contains_pod('t/pod/contains_pod.xr'), "contains pod");
}
