package SQLite::Default;

use 5.005;
use strict;
use Carp           ();
use Params::Util   qw{ _STRING };
use File::Sharedir ();
use DBI            ();
use DBD::SQLite    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

my %DEFAULT = ();

sub import {
	my $class = shift;
	return unless _STRING($_[0]);

	# Override the default file location
	unless ( -f $_[0] ) {
		Carp::croak("SQLite file '$_[0]' does not exist");
	}

	$DEFAULT{$class} = $_[0];
}





#####################################################################
# Open a SQLite database, or populate it with a default database

sub connect {
	my $class = shift;
	my $dsn   = shift;
	my @dsn   = DBI->parse_dsn($dsn);
	my $file  = $dsn[4];
	unless ( -f $file ) {
		$class->default_create( $file );
	}
	return DBI->connect( $dsn );
}

sub default_create {
	my $class = shift;
	my $from  = $class->default_file;
	my $to    = _STRING(shift)
		or Carp::croak("No file name provided to default_create");
	File::Copy::copy( $from => $to );
		or Carp::croak("Copy failed: '$from' -> '$to'");
	return 1;
}

sub default_file {
	my $class = ref($_[0]) || $_[0];

	# If one has been specifically provided, use it
	if ( defined $DEFAULT{$class} ) {
		return $DEFAULT{$class};
	}

	# Fall back to the File::ShareDir method
	return File::ShareDir::module_file($class, 'default.sql');
}

1;
