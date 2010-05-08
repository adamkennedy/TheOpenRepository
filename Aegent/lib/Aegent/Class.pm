package Aegent::Class;

use 5.008007;
use strict;

our $VERSION = '0.01';





######################################################################
# Moose Structure

use Moose;
use Moose::Util::TypeConstraints ();

Moose::Util::TypeConstraints::subtype(
	AegentClass => (
		as    => 'ClassName',
		where => sub {
			$_->isa('Aegent::Object')
		},
	)
);

has name => (
	is        => 'ro',
	isa       => 'AegentClass',
	required  => 1,
);

has sequence => (
	is        => 'ro',
	isa       => 'Int',
	required  => 1,
	default   => 0,
	traits    => [ 'Counter' ],
	handles   => {
		sequence_nextval => 'inc',
	},
);

has attr => (
	is        => 'bare',
	isa       => 'HashRef[Aegent::Attribute]',
	required  => 1,
	default   => sub { { } },
	traits    => [ 'Hash' ],
	handles   => {
		attr_exists => 'exists',
		attr_get    => 'get',
		attr_set    => 'set',
		attr_keys   => 'keys',
	},
);





######################################################################
# Main Methods

sub alias {
	join '.', $_[0]->name, $_[0]->sequence_nextval
}

1;
