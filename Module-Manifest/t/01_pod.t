#!/usr/bin/perl -T

# t/01_pod.t
#  Checks that POD commands are correct
#
# $Id$

use strict;
BEGIN {
  $^W = 1;
}

use Test::More;

eval 'use Test::Pod 1.14';
if ($@) {
  plan skip_all => 'Test::Pod 1.14 required to test POD';
}

all_pod_files_ok();
