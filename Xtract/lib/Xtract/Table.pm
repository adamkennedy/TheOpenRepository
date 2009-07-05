package Xtract::Table;

# Object that represents a single table in the destination database.

use 5.008005;
use Moose;
use MooseX::Types::Common::Numeric 'PositiveInt';
use Params::Util '_IDENTIFIER';

our $VERSION = '0.11';

has name => {
	is  => 'ro',
	isa => 'Str',
};

subtype XtractTableName
	=> as 'Str'
	=> where {
		defined _IDENTIFIER($_)
		and
		$_ eq lc($_)
	}
	=> 

no Moose;
__PACKAGE__->meta->make_immutable;

1;
