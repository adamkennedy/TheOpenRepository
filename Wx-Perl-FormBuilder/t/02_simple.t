#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use Wx::Perl::FormBuilder;

# Find the sample file
my $file = File::Spec->catfile( 't', 'data', 'simple.fbp' );
ok( -f $file, "Found test file $file" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($file), '->parse_file ok' );

# Create the generator object
my $object = Wx::Perl::FormBuilder->new(
	dialog => $fbp->dialog('MyDialog1'),
);
isa_ok( $object, 'Wx::Perl::FormBuilder' );
