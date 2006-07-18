package ADAMK::Debug;

# Provides the collection of functions for apld

use strict;
use Exporter ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.02';
	@EXPORT  = qw{
		in_distroot has_makefile
		MakefilePL  Makefile
		verbose     message
		error       run
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

sub MakefilePL () {
	catfile( curdir(), 'Makefile.PL' );
}

sub Makefile () {
	catfile( curdir(), 'Makefile' );
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

1;
