package pler;

use 5.005;
use strict;
use Config;
use File::Which ();
use File::Spec::Functions ':ALL';
use File::Find::Rule ();
use Devel::Pler;

# Convenience constants
use constant FFR  => 'File::Find::Rule';

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.18';
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
	if ( needs_makefile or old_makefile ) {
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

