#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Request class

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			);
	}
}

use Test::More tests => 12;
use PITA::Report ();

my $md5sum = '0123456789ABCDEF0123456789ABCDEF';

# Create a new object
my $dist = PITA::Report::Request->new(
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	filename => 'Foo-Bar-0.01.tar.gz',
	md5sum   => $md5sum,
	);
isa_ok( $dist, 'PITA::Report::Request' );
is( $dist->distname, 'Foo-Bar', '->distname matches expected'             );
is( $dist->filename, 'Foo-Bar-0.01.tar.gz', '->filename matches expected' );
is( $dist->md5sum, lc($md5sum), '->md5sum is normalised as expected'      );
is( $dist->authority, '', '->authority returns "" as expected'            );
is( $dist->authpath, '', '->authpath returns "" as expected'              );

# Create a new CPAN dist
my $cpan = PITA::Report::Request->new(
	scheme    => 'perl5',
	distname  => 'Task-CVSMonitor',
	filename  => 'Task-CVSMonitor-0.006003.tar.gz',
	md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
	authority => 'cpan',
	authpath  => '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
	);
isa_ok( $cpan, 'PITA::Report::Request' );
is( $cpan->distname, 'Task-CVSMonitor', '->distname matches expected' );
is( $cpan->filename, 'Task-CVSMonitor-0.006003.tar.gz',
	'->filename matches expected' );
is( $cpan->md5sum, '5cf0529234bac9935fc74f9579cc5be8',
	'->md5sum matches expected' );
is( $cpan->authority, 'cpan',
	'->authority returns as expected' );
is( $cpan->authpath, '/authors/id/A/AD/ADAMK/Task-CVSMonitor-0.006003.tar.gz',
	'->authpath returns as expected' );

exit(0);
