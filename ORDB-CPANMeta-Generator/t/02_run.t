#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 11;
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

my $sqlite = catfile( 't', 'sqlite.db' );
clear( $sqlite );
ok( ! -f $sqlite, "Database '$sqlite' does not exist" );


 


#####################################################################
# Main Tests

# Create the generator
my $cpandb = new_ok( 'ORDB::CPANMeta::Generator' => [
	minicpan => $minicpan,
	sqlite   => $sqlite,
	trace    => 0,
] );
clear($cpandb->sqlite);

# Run the generator
ok( $cpandb->run, '->run ok' );

# Validate the result
ok( -f $sqlite, "Created database '$sqlite'" );
foreach my $file ( qw{
	cpanmeta.gz
	cpanmeta.bz2
	cpanmeta.lz
} ) {
	ok( -f $file, "File '$file' exists" );
}
