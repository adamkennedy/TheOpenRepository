#!/usr/bin/perl

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.98';
}

use Test::More tests => 8;
use File::Spec;
use File::Spec::Unix;
use IPC::Run3;

ok( $] >= 5.005, 'Perl version is new enough' );

local $ENV{TEST_LETMEIN} = 1;
my $script = File::Spec->catfile( 'script', 'letmein' );
ok( -f $script, 'script/letmein exists' );
require_ok( $script );
use_ok( 't::lib::Test'      );
use_ok( 't::lib::LetMeIn'  );
use_ok( 'LetMeIn::Install' );

script_compiles_ok( 'script/letmein'    );
script_compiles_ok( 'script/letmein.pl' );

# is( $LetMeIn::VERSION, $VERSION, 'Versions match' );





#####################################################################
# Inlined from Test::Script

sub script_compiles_ok {
	my $unix   = shift;
	my $name   = shift || "Script $unix compiles";
	my $path   = path( $unix );
	my $cmd    = [ $^X, '-c', '-Mblib', $path ];
	my $stderr = '';
	my $rv     = IPC::Run3::run3( $cmd, \undef, \undef, \$stderr );
	my $ok     = !! ( $rv and $stderr =~ /syntax OK\s+$/si );
        ok( $ok, $name );
	# Add this once I can make the tests work ok
        diag( $stderr ) unless $ok;
	return $ok;
}

sub path ($) {
	my $path = shift;
	unless ( defined $path ) {
		Carp::croak("Did not provide a script name");
	}
	if ( File::Spec::Unix->file_name_is_absolute($path) ) {
		Carp::croak("Script name must be relative");
	}
	File::Spec->catfile( File::Spec->curdir, split /\//, $path );
}
