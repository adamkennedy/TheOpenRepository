package Aegent::Attribute;

use 5.008007;
use strict;
use Params::Util ();

our $VERSION = '0.01';





######################################################################
# Moose Structure

use Moose;
use Moose::Util::TypeConstraints ();

Moose::Util::TypeConstraints::subtype(
	AegentAttribute => (
		as    => 'Str',
		where => sub {
			Params::Util::_IDENTIFIER($_)
		},
	)
);

no Moose;

1;
