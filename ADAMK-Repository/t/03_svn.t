#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 115 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use File::Spec::Functions ':ALL';
use ADAMK::Repository;

my $uuid = '88f4d9cd-8a04-0410-9d60-8f63309c3137';





#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new(
	path    => $ENV{ADAMK_CHECKOUT},
	preload => 1,
);
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->path, $ENV{ADAMK_CHECKOUT}, '->path ok' );





#####################################################################
# SVN Methods

my $info = $repository->info;
isa_ok( $info, 'ADAMK::SVN::Info' );
is(
	$info->url,
	'http://svn.ali.as/cpan',
	'info: Repository Root ok',
);
is(
	$info->{RepositoryUUID},
	$uuid,
	'info: Repository UUID ok',
);
is(
	$info->{NodeKind},
	'directory',
	'info: Node Kind ok',
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
	} $repository->distributions_released;
	foreach my $distribution ( sort @distributions[0 .. 25] ) {
		my $info = $distribution->info;
		isa_ok( $info, 'ADAMK::SVN::Info' );
	}

	# Check a typical info
	my $first = $distributions[0];
	diag("Testing " . $first->name . "\n");
	my $info = $first->info;
	isa_ok( $info, 'ADAMK::SVN::Info' );
	my $url      = $info->url;
	my $revision = $info->revision;
	like( $url, qr/^http:\/\/svn\.ali\.as\/cpan/, '->url ok' );
	like( $revision, qr/^\d+$/, '->revision ok' );

	# Check Changes file in the current distribution
	SCOPE: {
		my $changes = $first->changes;
		isa_ok( $changes, 'Module::Changes::ADAMK' );
	}

	# Checkout a distribution
	SCOPE: {
		my $checkout = $first->checkout;
		isa_ok( $checkout, 'ADAMK::Distribution::Checkout' );
		isa_ok( $checkout->distribution, 'ADAMK::Distribution' );
		isa_ok( $checkout->repository,   'ADAMK::Repository'   );
		my @releases = $first->releases;
		isa_ok( $releases[0], 'ADAMK::Release' );
		my $name = $checkout->name;
		my $path = $checkout->path;
		ok( -d $path, "->export directory '$path' for distribution '$name' exists" );
		ok( -f catfile($path, 'Makefile.PL'), '->export/Makefile.PL exists' );

		# Test svn info in checkouts
		my $info = $checkout->info;
		isa_ok( $info, 'ADAMK::SVN::Info' );
		is( $info->{RepositoryUUID}, $uuid, 'RepositoryUUID ok' );

		# Test Changes integration
		my $changes = $checkout->changes;
		isa_ok( $changes, 'Module::Changes::ADAMK' );
		ok(
			$checkout->update_current_release_datetime,
			'->update_current_release_datetime ok',
		);

		# Test svn log support
		my @lines = $checkout->svn_log;
		isa_ok( $lines[0], 'ADAMK::SVN::Log' );
	}

	# Export a distribution
	SCOPE: {
		my $export = $first->export( $revision );
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
	} map {
		$_->latest
	} grep {
		-f catfile($_->path, 'Makefile.PL')
		and
		-f catfile($_->path, 'Changes')
	} $repository->distributions_released;
	foreach my $release ( sort @releases[0 .. 25] ) {
		my $info = $release->info;
		isa_ok( $info, 'ADAMK::SVN::Info' );
		isa_ok( $release->distribution, 'ADAMK::Distribution' );
	}

	# Check a typical info
	my $first = $releases[0];
	diag("Testing " . $first->file . "\n");
	my $revision = $first->info->revision;
	like( $revision, qr/^\d+$/, '->revision ok ok' );

	# Export a release
	SCOPE: {
		my $export = $first->export;
		isa_ok( $export, 'ADAMK::Distribution::Export' );
		ok( -d $export->path, '->path directory exists' );
		ok(
			-f catfile($export->path, 'Makefile.PL'),
			'->path/Makefile.PL exists'
		);
	}

	# Extract a release
	SCOPE: {
		my $extract = $first->extract;
		isa_ok( $extract, 'ADAMK::Release::Extract' );
		ok( -d $extract->path, '->path directory exists' );
		ok(
			-f catfile($extract->path, 'Makefile.PL'),
			'->path/Makefile.PL exists',
		);
		isa_ok( $extract->changes, 'Module::Changes::ADAMK' );
	}
}





#####################################################################
# Find the revision of the latest release for a distribution

SCOPE: {
	my $dist = $repository->distribution('CPAN-Test-Dummy-Perl5-Developer');
	isa_ok( $dist, 'ADAMK::Distribution' );

	my $latest = $dist->latest;
	isa_ok( $latest, 'ADAMK::Release' );

	my $revision = $latest->info->revision;
	is( $revision, 1370, '->info->revision returns expected version' );
}
