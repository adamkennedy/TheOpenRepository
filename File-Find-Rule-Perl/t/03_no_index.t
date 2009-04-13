#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 20;
use File::Spec::Functions ':ALL';
use File::Find::Rule       ();
use File::Find::Rule::Perl ();

use constant FFR => 'File::Find::Rule';





#####################################################################
# Run four variations of the standard query

SCOPE: {
	my @params = (
		[ ],
		[ curdir() ],
		[ 'META.yml' ],
		[ { directory => [ 'inc', 't' ] } ],
	);

	foreach my $p ( @params ) {
		my $rule  = FFR->relative->no_index(@$p)->file;
		isa_ok( $rule, 'File::Find::Rule' );

		my %ignore = map { $_ => 1 } qw{
			Makefile
			MANIFEST
			LICENSE
			README
			pm_to_blib
		};
		my @files = sort grep {
			! /\.svn\b/
			and
			! /\bblib\b/
			and
			! $ignore{$_}
		} $rule->in( curdir() );

		is_deeply( \@files, [ qw{
			Changes
			META.yml
			Makefile.PL
			lib/File/Find/Rule/Perl.pm
		} ], 'Found the expected files' );
	}
}





#####################################################################
# Run a test in a relative subdirectory
# Test with and without ->relative, and with and without a relative ->in

# With relative enabled
SCOPE: {
	my $dir = catdir('t', 'dist');
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->relative->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is_deeply( \@files, [ qw{
		META.yml
		lib/Foo.pm
	} ], 'Found the expected files' );
}

# With relative disabled
SCOPE: {
	my $dir = catdir('t', 'dist');
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is( scalar(@files), 2, 'Found the same file quantity' );
}

# With relative enabled
SCOPE: {
	my $dir = rel2abs(catdir('t', 'dist'));
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->relative->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is_deeply( \@files, [ qw{
		META.yml
		lib/Foo.pm
	} ], 'Found the expected files' );
}

# With relative disabled
SCOPE: {
	my $dir = rel2abs(catdir('t', 'dist'));
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is( scalar(@files), 2, 'Found the same file quantity' );
}
