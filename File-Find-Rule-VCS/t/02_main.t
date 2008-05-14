#!/usr/bin/perl

# Testing for File::Find::Rule::VCS

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 5;
use File::Find::Rule      ();
use File::Find::Rule::VCS ();
use constant FFR => 'File::Find::Rule';

# Check the methods are added
ok( FFR->can('ignore_vcs'), '->ignore_vcs method exists' );
ok( FFR->can('ignore_cvs'), '->ignore_cvs method exists' );
ok( FFR->can('ignore_svn'), '->ignore_svn method exists' );
ok( FFR->can('ignore_bzr'), '->ignore_bzr method exists' );

# Make an object containing all of them, to ensure there are no errors
my $Rule = File::Find::Rule->new
                           ->ignore_cvs
                           ->ignore_svn
                           ->ignore_bzr
                           ->ignore_vcs('')
                           ->ignore_vcs('cvs')
                           ->ignore_vcs('svn')
                           ->ignore_vcs('bzr');
isa_ok( $Rule, 'File::Find::Rule' );
