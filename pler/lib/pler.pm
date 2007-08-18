package pler;

# See 'sub main' for main functionality

use 5.005;
use strict;
use Config;
use Carp                  'croak';
use File::Which           ();
use File::Spec::Functions ':ALL';
use File::Find::Rule      ();

# Convenience constants
use constant FFR     => 'File::Find::Rule';

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.20';
}

# Does exec work on this platform
use constant EXEC_OK => ($^O ne 'MSWin32' and $^O ne 'cygwin');

# Can you overwrite an open file on this platform
use constant OVERWRITE_OK => !! ( $^O ne 'MSWin32' );





#####################################################################
# Resource Locations

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
# Convenience Logic

sub in_distroot () {
	!! -f MakefilePL;
}

sub in_subdir () {
        !! -f catfile( updir(), 'Makefile.PL' );
}

sub has_makefile () {
	!! -f Makefile;
}

sub has_makefilepl () {
	!! -f MakefilePL;
}

sub has_blib () {
	!! -d blib;
}

sub has_lib () {
	!! -d lib;
}

sub needs_makefile () {
	has_makefilepl and ! has_makefile;
}

sub old_makefile () {
	has_makefile
	and
	has_makefilepl
	and
	(stat(Makefile))[4] < (stat(Makefile))[4];
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
        print $_[0];
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





#####################################################################
# Main Script

sub main {
        my $script = shift @ARGV;
        unless ( defined $script ) {
                print "# No file name pattern provided, using 't'...\n";
                $script = 't';
        }

        # Can we locate the distribution root directory
        if ( in_subdir ) {
                chdir updir();
        }
        unless ( in_distroot ) {
                error "Failed to locate the distribution root";
        }

	# Build, or rebuild, the Makefile if needed.
	# Currently we do not support Build.PL or remembering previous Makefile.PL params
	if ( needs_makefile or (old_makefile and ! OVERWRITE_OK) ) {
		run( join ' ', perl, MakefilePL );
	}

	# Locate the test script to run
        unless ( $script =~ /\.t$/ ) {
                # Get the list of possible tests
                my @possible = FFR->file->name('*.t')->in( 't' );

                # If a number, look for a numeric match
                my $pattern = quotemeta $script;
                my @matches = grep { /$pattern/ } @possible;
                unless ( @matches ) {
                        error "No tests match '$script'";
                }
                if ( @matches > 1 ) {
                        error(
                                "More than one possible test",
                                map { "  $_" } sort @matches,
                        );
                }
                $script = $matches[0];

                # Localize the path
                $script = File::Spec->catfile( split /\//, $script );
        }
        unless ( -f $script ) {
                error "Test script '$script' does not exist";
        }

        # Rerun make if needed
        if ( in_distroot and has_makefile ) {
                run( make );
        }

        # Build the command to execute
        my @flags = ();
        if ( has_blib ) {
                push @flags, '-Mblib';
        } elsif ( has_lib ) {
                push @flags, '-Ilib';
        }

        # Hand off to the perl debugger
        unless ( pler->is_verbose ) {
                message( "# Debugging $script" );
        }
        my @cmd = ( perl, @flags, '-d', $script );
        handoff( @cmd );
}

1;

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

- Tweak some small terminal related issues on Win32

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=pler>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<prove>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
