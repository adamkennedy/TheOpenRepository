#!perl

use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use File::Remove qw();

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'No TEST_AUTHOR: Skipping author test';
    plan skip_all => $msg;
}

eval { require Test::Prereq; };
plan skip_all => 
    'Test::Prereq required for testing prerequisites' if $EVAL_ERROR;

diag('Takes a few minutes...');
Test::Prereq->import();
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

prereq_ok(5.006, 'Check prerequisites', \@modules_skip);

# File::Remove::remove( \1, 't\inc' );
