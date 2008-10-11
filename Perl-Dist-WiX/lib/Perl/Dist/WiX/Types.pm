package Perl::Dist::WiX::Types;

# Convert or emulate various useful Params::Util assertions as Moose types

use 5.008;
use Params::Util ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Moose Declarations

use Moose;
use Moose::Util::TypeConstraints;

subtype Identifier => as Str => where {
	Params::Util::_IDENTIFIER($_)
};

subtype PosInt => as Int => where {
	$_ > 0
};

subtype NonNegInt => as Int => where {
	$_ >= 0
};

subtype WinVersion => as Str => where {
	/^\d+(?:\.\d+){1,3}$/
};

subtype WinGuid => as Str => where {
	/^\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$/
};

subtype WinAutogenGuid => as Str => where {
	/^(?:\*|\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\})$/
};

1;
