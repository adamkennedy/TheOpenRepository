package Business::AU::Data::ANZIC;

use 5.005;
use strict;
use IO::File       ();
use Params::Util   '_CLASS';
use File::ShareDir ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Locate the file
my $cvs_file = File::ShareDir::module_file('Business::AU::Data::ANZIC', 'anzic.csv');






#####################################################################

sub new {
	my $class = shift;
	my $self  = bless { }, $class;
	return $self;
}

sub provides {
	my @provides = qw{ IO::File Parse::CSV };
	my $want     = _CLASS($_[1]);
	if ( $want ) {
		return grep { $_->isa($want) } @provides;
	} else {
		return @provides;
	}
}

sub get {
	my $class = shift;
	my $want  = 
}

sub _io_file {
	IO::File->new( $csv_file );
}

sub _parse_csv {
	Parse::CSV->new(
		file => $csv_file,
		);
}

1;
