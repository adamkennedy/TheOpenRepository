#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
use Perl::Portable ();

# Override the perl path for testing purposes
$Perl::Portable::FAKE_PERL = rel2abs(catfile(qw{
	t data perl bin perl.exe
}));

# Create an object
my $perl = Perl::Portable->default;
isa_ok( $perl, 'Perl::Portable' );
