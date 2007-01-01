package pler;

# Provides the collection of functions for pler

use 5.005;
use strict;
use Carp        'croak';
use Config      ();
use Exporter    ();
use File::Which ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.15';
	@ISA     = qw{ Exporter };
	@EXPORT  = qw{
		in_distroot has_makefile has_blib has_lib
		MakefilePL  Makefile     perl     make     
		blib        lib
		verbose     message
		error       run          handoff
		};
}

# Does exec work on this platform
use constant EXEC_OK => ($^O ne 'MSWin32' and $^O ne 'cygwin');





#####################################################################
# Convenience Functions

sub in_distroot () {
	!! -f MakefilePL();
}

sub has_makefile () {
	!! -f Makefile();
}

sub has_blib () {
	!! -d blib();
}

sub has_lib () {
	!! -d lib();
}

sub MakefilePL () {
	catfile( curdir(), 'Makefile.PL' );
}

sub Makefile () {
	catfile( curdir(), 'Makefile' );
}

sub perl () {
	my $perl = $^X;
	if ( $perl eq 'perl' and ! -f $perl ) {
		# Some platforms don't provide an absolute $^X
		# Apply File::Which in this case
		$perl = File::Which::which( $perl );
	}
	unless ( -f $perl ) {
		croak("Failed to find perl at '$perl'");
	}
	return $perl;
}

# Look for make in $Config
sub make () {
	my $make  = $Config::Config{make};
	my $found = File::Which::which( $make );
	unless ( $found ) {
		croak("Failed to find '$make' (as specified by \$Config{make})");
	}
	return $found;
}

sub blib () {
	catdir( curdir(), 'blib' );
}

sub lib () {
	catdir( curdir(), 'lib' );
}





#####################################################################
# Utility Functions

# Support verbosity
use vars qw{$VERBOSE};
BEGIN {
	$VERBOSE ||= 0;
}

sub is_verbose {
	$VERBOSE;
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

sub handoff (@) {
	my $cmd = join ' ', @_;
	verbose( "> $cmd" );
	if ( EXEC_OK ) {
		exec( @_ ) or croak("Failed to exec '$cmd'");
	} else {
		system( @_ );
		exit(0);
	}
}

1;

# Since not everything is smart about where to pull things from,
# we add a copy of the POD docs here.

=pod

=head1 NAME

pler - The DWIM Perl Debugger

=head1 DESCRIPTION

B<pler> is a small script which provides a sanity layer for debugging
test scripts in Perl distributions.

While L<prove> has proven itself to be a highly useful program for
manually running one or more groups of scripts in a distribution,
what we also need is something that provides a similar level of
intelligence in a debugging context.

B<pler> checks that the environment is sound, runs some cleanup tasks
if needed, makes sure you are in the right directory, and then hands off
to the perl debugger as normal.

=head1 TO DO

- Allow execution from the base or F<t> directory.

- Automatically run the F<Makefile.PL> if it needs to be

- Write a heuristic to determine if it needs to be

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Pler>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<prove>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2007 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
