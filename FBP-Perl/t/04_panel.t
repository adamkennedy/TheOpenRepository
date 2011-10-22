#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use Test::NoWarnings;
use t::lib::Test;
use FBP::Perl;

# Find the sample files
my $input  = File::Spec->catfile( 't', 'data', 'simple.fbp' );
my $output = File::Spec->catfile( 't', 'data', 'panel.pl'  );
ok( -f $input,  "Found test file $input"  );
ok( -f $output, "Found test file $output" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($input), '->parse_file ok' );

# Create the generator object
my $project = $fbp->find_first(
	isa => 'FBP::Project',
);
my $code = FBP::Perl->new(
	project => $project,
	version => $FBP::Perl::VERSION,
	prefix  => 1,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );

# Test Dialog string generators
my $panel = $fbp->form('MyPanel1');
isa_ok( $panel, 'FBP::FormPanel' );

# Generate the entire dialog constructor
my $have = $code->panel_class($panel);
my $want = slurp($output);
code( $have, $want, '->panel_class ok' );
compiles( $have, 'Panel class compiled' );
