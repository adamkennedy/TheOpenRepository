#!perl

use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catfile curdir);
eval 'use Test::Pod 1.14';
plan $@ ? (skip_all => 'Test::Pod 1.14 required for testing POD') : tests => 2;

pod_file_ok( catfile( curdir(), qw(lib Perl Dist WiX.pm) ) , 'WiX.pm pod');
pod_file_ok( catfile( curdir(), qw(lib Perl Dist WiX Installer.pm) ) , 'WiX\Installer.pm pod');
