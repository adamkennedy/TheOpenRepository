package AI::RandomForest::Table;

use 5.16.0;
use strict;
use warnings;
use Params::Util 1.00 ();

our $VERSION = '0.01';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless [ @_ ], $class;

	unless ( $self->samples ) {
		die "Table must contain at least one sample";
	}

	return $self;
}

sub from_csv {
	my $class = shift;
	my $parser = Params::Util::_INSTANCE(shift, 'Parse::CSV');
	unless ( $parser ) {
		die "Missing or invalid CSV param";
	}

	# Parse the CSV file into a fresh table
	my @rows = ();
	while ( my $row = $parser->fetch ) {
		push @rows, $row;
	}

	return $class->new(@rows);
}

sub samples {
	return @{$_[0]};
}

sub features {
	return keys %{ $_[0]->[0] }
}

1;
