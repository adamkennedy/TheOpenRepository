#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 9;
use File::Spec::Functions     ':ALL';
use File::Remove              'clear';
use ORDB::CPANMeta::Generator ();

my @archives = qw{
	cpanmeta.gz
	cpanmeta.bz2
	cpanmeta.lz
};
clear( @archives );
foreach my $file ( @archives ) {
	ok( ! -f $file, "File '$file' does not exist" );
}

my $minicpan = catdir( 't', 'minicpan' );
ok( -d $minicpan, 'Found minicpan directory' );





#####################################################################
# Main Tests

# Create the generator
my $generator = ORDB::CPANMeta::Generator->new(
	minicpan => $minicpan,
	trace    => 0,
);
isa_ok( $generator, 'ORDB::CPANMeta::Generator' );

# Remove the operating files that anyone made before us
clear( $generator->dir );

# Run the generator
ok( $generator->run, '->run ok' );

# Validate the result
foreach my $file ( qw{
	cpanmeta.gz
	cpanmeta.bz2
	cpanmeta.lz
} ) {
	ok( -f $file, "File '$file' exists" );
}
