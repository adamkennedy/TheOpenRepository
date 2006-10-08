#!/usr/bin/perl -w

# Main testing for CPAN::Inject

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use File::Remove          'remove';
use CPAN::Inject;

# Create a testing root directory
my $sources = catdir('t', 'sources');
      if ( -e $sources ) { remove( \1, $sources ) }
END { if ( -e $sources ) { remove( \1, $sources ) } }
ok( ! -e $sources, 'No existing sources directory' );
mkdir $sources;
ok( -e $sources, 'Created sources directory' );



1;
