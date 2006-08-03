package Devel::Pler;

# Provides the collection of functions for pler

use strict;
use Carp     ();
use Exporter ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.13';
	@ISA     = qw{ Exporter };
	@EXPORT  = qw{
		in_distroot has_makefile has_blib has_lib
		MakefilePL  Makefile     blib     lib
		verbose     message
		error       run          handoff
		};
}





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

sub handoff ($) {
	my $cmd = shift;
	verbose( "> $cmd" );
	exec( $cmd ) or Carp::croak("Failed to exec '$cmd'");
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

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
