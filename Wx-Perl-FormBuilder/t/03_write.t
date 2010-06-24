#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::NoWarnings;
use Padre::FormBuilder;

# Find the sample file
my $file = File::Spec->catfile( 't', 'data', 'padre.fbp' );
ok( -f $file, "Found test file $file" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($file), '->parse_file ok' );

# Create the generator object
my $project = $fbp->find_first(
	isa => 'FBP::Project',
);
my $code = Padre::FormBuilder->new(
	project => $project,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'Wx::Perl::FormBuilder' );

$code->dialog_write(
	$project->find_first( name => 'Padre::Wx::Dialog::OpenURL' ),
	'OpenURL.pm',
);
