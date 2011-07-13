package EVE::Xtract;

# Convert the EVE Online MySQL database to SQLite

use 5.008;
use strict;
use warnings;
use Xtract ();

our $VERSION = '0.01';
our @ISA     = 'Xtract';

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new( @_,
		
		
}

1;
