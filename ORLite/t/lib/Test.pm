package t::lib::Test;

use strict;
use Exporter   ();
use ORLite     ();
use Test::More ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.06';
	@ISA     = qw{ Exporter };
	@EXPORT  = qw{ test_db connect_ok create_ok };
}





#####################################################################
# Test Methods

my %to_delete = ();
END {
	foreach my $file ( sort keys %to_delete ) {
		unlink $file;
	}
}

sub test_db {
	my $file = catfile( @_ ? @_ : 't', 'sqlite.db' );
	unlink $file if -f $file;
	$to_delete{$file} = 1;
	return $file;
}

sub connect_ok {
	my $dbh = DBI->connect(@_);
	Test::More::isa_ok( $dbh, 'DBI::db' );
	return $dbh;
}

sub create_ok {
	# Read the create script
	my $file = shift;
	local *FILE;
	local $/ = undef;
	open( FILE, $file )          or die "open: $!";
	defined(my $buffer = <FILE>) or die "readline: $!";
	close( FILE )                or die "close: $!";

	# Get a database connection
	my $dbh = connect_ok(@_);

	# Create the tables
	my @statements = split( /\s*;\s*/, $buffer );
	foreach my $statement ( @statements ) {
		# Test::More::diag( "\n$statement" );
		$dbh->do($statement);
	}

	return $dbh;
}

1;
