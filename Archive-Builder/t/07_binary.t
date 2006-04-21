#!/usr/bin/perl -w

# Some tests for binary files

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 5;
use File::Flat;
use Archive::Builder;

# Create our Generator 
use vars qw{$Generator $Section};
sub init {
	$Generator = Archive::Builder->new();
	$Section = $Generator->new_section('section');
	$Section->new_file( 'text', 'main::direct', 'This is a text file' );
	$Section->new_file( 'binary', 'main::direct', "Binary\000files\000contain\000nulls" );
}
init();







########################################################################
# Save tests

# Adding additional file_count test in
is( $Generator->file_count, 2, '->file_count is correct' );
ok( defined $Generator->section('section')->file('text')->binary, '->binary on text file returns defined' );
ok( ! $Generator->section('section')->file('text')->binary, '->binary on text file returns false' );
ok( defined $Generator->section('section')->file('binary')->binary, '->binary on binary file returns defined' );
ok( $Generator->section('section')->file('binary')->binary, '->binary on binary file returns true' );

sub direct {
	my $File = shift;
	my $contents = shift;
	\$contents;
}
