package ADAMK::Debug;

# Provides the collection of functions for apld

use strict;
use Carp     ();
use Exporter ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.03';
	@EXPORT  = qw{
		in_distroot has_makefile has_blib
		MakefilePL  Makefile     blib
		verbose     message
		error       run          handoff
		};
}





#####################################################################
# Convenience Functions

sub in_distroot () {
	!! -f MakefilePL;
}

sub has_makefile () {
	!! -f Makefile;
}

sub has_blib () {
	!! -d blib();
}

sub MakefilePL () {
	catfile( curdir(), 'Makefile.PL' );
}

sub Makefile () {
	catfile( curdir(), 'Makefile' );
}

sub blib () {
	catdir( curdir(), 'blib' );
}





#####################################################################
# Utility Functions

# Support verbosity
use vars qw{$VERBOSE};
BEGIN {
	$VERBOSE ||= 0;
}

sub verbose ($) {
	message( $_[0] ) if $VERBOSE;
}

sub message ($) {
	print ' ' . $_[0];
}

sub error (@) {
	print ' ' . join '', map { "$_\n" } ('', @_, '');
	exit(255);
}

sub run ($) {
	my $cmd = shift;
	verbose( "> $cmd" );
	system( $cmd );
}

sub handoff ($) {
	my $cmd = shift;
	verbose( "> $cmd" );
	exec( $cmd ) or Carp::croak("Failed to exec '$cmd'");
}

1;
