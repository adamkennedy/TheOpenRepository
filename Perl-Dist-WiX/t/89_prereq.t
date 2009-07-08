#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq 1.036',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

#plan( skip_all => 'Test is buggy at the moment' );
#exit(0);

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

# Terminate leftovers with prejudice aforethought.
require File::Remove;
foreach my $dir ( 't\tmp50', 't\tmp90', 't\tmp91', 't\tmp92', 't\tmp93' ) {
	File::Remove::remove( \1, $dir ) if -d $dir;
}

my @modules_skip = (
# Perl::Dist prerequisites - 
#   since we have Perl::Dist as a prereq, I'm not
#   listing all of them in the Makefile.PL.
#   Enough's there as is! 
       'Archive::Tar',
       'Archive::Zip',
       'File::Spec',
       'File::Copy::Recursive',
       'File::Find::Rule',
       'File::Path',
       'File::pushd',
       'File::Remove',
       'File::HomeDir',
       'File::ShareDir',
       'File::PathList',
       'File::Temp',
       'HTTP::Status',
       'IPC::Run3',
       'LWP::UserAgent',
       'LWP::UserAgent::WithCache',
       'LWP::Online',
       'Object::Tiny',
       'YAML::Tiny',
       'Module::CoreList',
       'Params::Util',
       'Template',
       'CPAN',
       'PAR::Dist',
       'Process',
       'Process::Storable',
       'Process::Delegatable',
       'IO::Capture',
       'Win32::File::Object',
       'Portable::Dist',
       'Probe::Perl',
# Needed only for tests
	   't::lib::Test',
# Needed only for AUTHOR_TEST tests
       'Perl::Critic::More',
       'Test::HasVersion',
       'Test::MinimumVersion',
       'Test::Perl::Critic',
       'Test::Prereq',
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

use File::Copy qw();

File::Copy::move( 't\inc\Module\Install.pm', 'inc\Module\Install.pm' );
File::Remove::remove( \1, 't\inc' );
