#!/usr/bin/perl -w

# Constructor/connection testing for JSAN::Transport

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
			'lib',
			);
	}
}

use Test::More tests => 21;

my $sqlindex = 'index.sqlite';




#####################################################################
# Tests

use JSAN::Transport verbose => 0;

# Create a new default object
isa_ok( JSAN::Transport->_self,        'JSAN::Transport' );
isa_ok( JSAN::Transport->_self->_self, 'JSAN::Transport' );
isa_ok( JSAN::Transport->mirror_location, 'HTML::Location' );
ok( JSAN::Transport->mirror_remote, '->mirror_remote returns true'  );
ok( JSAN::Transport->mirror_local,  '->mirror_local returns true'   );
is( JSAN::Transport->verbose, '',   '->verbose is false by default' );

# Pull the index as a test
my $location = JSAN::Transport->file_location($sqlindex);
isa_ok( $location, 'HTML::Location' );
my $qm_sqlindex = quotemeta $sqlindex;
ok( $location->uri =~ /$qm_sqlindex$/, '->file_location actually appends filename' );
my $rv = JSAN::Transport->file_get($sqlindex);
isa_ok( $rv, 'HTML::Location' );
is_deeply( $location, $rv, '->file_get returns HTML::Location as expected' );
ok( -f $rv->path, '->file_get actually gets the file to the expected location' );
is( JSAN::Transport->file_get('nosuchfile'), '', "->file_get(nosuchfile) returns ''" );

# Pull again via mirror
$rv = JSAN::Transport->file_mirror($sqlindex);
isa_ok( $rv, 'HTML::Location' );
is_deeply( $location, $rv, '->file_mirror returns HTML::Location as expected' );
ok( -f $rv->path, '->file_mirror actually gets the file to the expected location' );
is( JSAN::Transport->file_get('nosuchfile'), '', "->file_mirror(nosuchfile) returns ''" );

# Check the index methods
ok( JSAN::Transport->index_file,      '->index_file returns true' );
ok( -f JSAN::Transport->index_file,   '->index_file exists'       );
ok( JSAN::Transport->index_dsn,       '->index_dsn returns true'  );
my $dbh = JSAN::Transport->index_dbh;
ok( $dbh, '->index_dbh returns true'  );
isa_ok( $dbh, 'DBI::db' );

exit(0);
