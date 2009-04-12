#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
	plan( tests => 107 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
}

use File::Spec::Functions ':ALL';
use ADAMK::Repository;

my $root = $ENV{ADAMK_CHECKOUT};
my $uuid = '88f4d9cd-8a04-0410-9d60-8f63309c3137';





#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new( root => $root );
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->root, $root, '->root ok' );





#####################################################################
# SVN Methods

my $hash = $repository->svn_info( $repository->root );
is( ref($hash), 'HASH', '->svn_info' );
is(
	$hash->{URL},
	'http://svn.ali.as/cpan',
	'svn_info: Repository Root ok',
);
is(
	$hash->{RepositoryUUID},
	$uuid,
	'svn_info: Repository UUID ok',
);
is(
	$hash->{NodeKind},
	'directory',
	'svn_info: Node Kind ok',
);





#####################################################################
# Distribution Methods

SCOPE: {
	my @distributions = sort {
		rand() <=> rand()
	} grep {
		-f catfile($_->path, 'Makefile.PL')
		and
		-f catfile($_->path, 'Changes')
	} $repository->distributions;
	foreach my $distribution ( sort @distributions[0 .. 25] ) {
		my $info = $distribution->svn_info;
		is( ref($info), 'HASH', $distribution->name . ': ->svn_info ok' );
	}

	# Check a typical svn_info
	my $first        = $distributions[0];
	diag("Testing " . $first->name . "\n");
	my $url          = $first->svn_url;
	my $last_changed = $first->svn_last_changed;
	like( $url,          qr/^http:\/\/svn\.ali\.as\/cpan/, '->svn_url ok' );
	like( $last_changed, qr/^\d+$/, '->last_changed ok' );

	# Checkout a distribution
	SCOPE: {
		my $checkout = $first->checkout;
		isa_ok( $checkout, 'ADAMK::Distribution::Checkout' );
		isa_ok( $checkout->distribution, 'ADAMK::Distribution' );
		isa_ok( $checkout->repository,   'ADAMK::Repository'   );
		my $name = $checkout->name;
		my $path = $checkout->path;
		ok( -d $path, "->export directory '$path' for distribution '$name' exists" );
		ok( -f catfile($path, 'Makefile.PL'), '->export/Makefile.PL exists' );

		# Test svn info in checkouts
		my $info = $checkout->svn_info;
		is( ref($info), 'HASH', '->svn_info returns a HASH' );
		is( $info->{RepositoryUUID}, $uuid, 'RepositoryUUID ok' );

		# Test Changes integration
		my $changes = $checkout->changes;
		isa_ok( $changes, 'Module::Changes::ADAMK' );
		ok(
			$checkout->update_current_release_datetime,
			'->update_current_release_datetime ok',
		);
	}

	# Export a distribution
	SCOPE: {
		my $export = $first->export( $last_changed );
		isa_ok( $export, 'ADAMK::Distribution::Export' );
		isa_ok( $export->distribution, 'ADAMK::Distribution' );
		isa_ok( $export->repository,   'ADAMK::Repository'   );
		my $name = $export->name;
		my $path = $export->path;
		ok( -d $path, "->export directory '$path' for distribution '$name' exists" );
		ok( -f catfile($path, 'Makefile.PL'), '->export/Makefile.PL exists' );
	}
}





#####################################################################
# Release Methods

SCOPE: {
	my @releases = sort {
		rand() <=> rand()
	} grep {
		-f catfile($_->distribution->path, 'Makefile.PL')
		and
		-f catfile($_->distribution->path, 'Changes')
	} $repository->releases_trunk;
	foreach my $release ( sort @releases[0 .. 25] ) {
		my $info = $release->svn_info;
		is( ref($info), 'HASH', $release->file . ': ->svn_info ok' );
		isa_ok( $release->distribution, 'ADAMK::Distribution' );
	}

	# Check a typical svn_info
	my $first    = $releases[0];
	diag("Testing " . $dist->file . "\n");
	my $revision = $first->svn_revision;
	like( $revision, qr/^\d+$/, '->revision ok ok' );

	# Export a distribution
	my $export = $first->export;
	isa_ok( $export, 'ADAMK::Distribution::Export' );
	ok( -d $export->path, '->path directory exists' );
	ok(
		-f catfile($export->path, 'Makefile.PL'),
		'->path/Makefile.PL exists'
	);
}





#####################################################################
# Find the revision of the latest release for a distribution

SCOPE: {
	my $dist = $repository->distribution('CPAN-Test-Dummy-Perl5-Developer');
	isa_ok( $dist, 'ADAMK::Distribution' );

	my $latest = $dist->latest;
	isa_ok( $latest, 'ADAMK::Release' );

	my $revision = $latest->svn_revision;
	is( $revision, 1370, '->svn_revision returns expected version' );
}
