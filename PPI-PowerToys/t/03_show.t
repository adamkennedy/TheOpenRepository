#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Probe::Perl ();
use IPC::Run3   ();

my $perl = Probe::Perl->find_perl_interpreter;
ok( -f $perl, 'Found perl interpreter' );

# Run show against ourself
my $script = 
my $stdout = '';
my $rv     = IPC::Run3::run3( [
	$perl,
	'-Mblib',
	,
], \undef, \$stdout, \undef );


foreach my $file ( qw{ adamk.pl padre.pl } ) {
	like( $stdout, qr/$file\.\.\.\s+0\.01/, "Found version for $file" );
}
