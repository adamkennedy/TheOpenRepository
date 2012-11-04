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
	my @names = @_ or die "Missing or invalid column names";
	return bless {
		columns => [ map { [ ]              } 0 .. $#names ],
		names   => [ map { $names[$_] => $_ } 0 .. $#names ],
	}, $class;
}

sub from_parse_csv {
	my $class  = shift;
	my $parser = Params::Util::_INSTANCE(shift, 'Parse::CSV');
	unless ( $parser ) {
		die "Missing or invalid Parse::CSV param";
	}
	if ( $parser->names ) {
		die "Parse::CSV should not use the 'names' param";
	}

	# Manually parse the names to create the table object
	my $names   = $parser->fetch;
	my $self    = $class->new(@$names);

	# Fill the table
	my $n       = 0;
	my @column  = @{$self->{columns}};
	my $columns = $#column;
	while ( my $row = $parser->fetch ) {
		$column[$_]->[$n] = $row->[$_] foreach 0 .. $columns;
		$n++;
	}

	return $self;
}

sub features {
	return scalar @{$_[0]->{columns}};
}

sub samples {
	return scalar @{$_[0]->{columns}->[0]};
}

1;
