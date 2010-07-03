#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 10;
use Test::NoWarnings;
use Test::LongString;
use FBP::Perl;

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	is_string( $left, $right, $_[0] );
}

sub compiles {
	my $code = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	SKIP: {
		skip("Skipping compile test for release", 1) if $ENV{ADAMK_RELEASE};
		my $rv = eval $code;
		# diag( $@ ) if $@;
		ok( $rv, $_[0] );
	}
}

# Provide a simple slurp implementation
sub slurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<', $file ) or die "open($file) failed: $!";
	my $text = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	return $text;
}

# Find the sample files
my $input  = File::Spec->catfile( 't', 'data', 'simple.fbp' );
my $output = File::Spec->catfile( 't', 'data', 'simple.pl'  );
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
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );

# Test Dialog string generators
my $dialog = $project->find_first( isa => 'FBP::Dialog' );
isa_ok( $dialog, 'FBP::Dialog' );

# Generate the entire dialog constructor
my $have = $code->dialog_class($dialog);
my $want = slurp($output);
code( $have, $want, '->dialog_super ok' );
compiles( $have, 'Dialog class compiled' );
