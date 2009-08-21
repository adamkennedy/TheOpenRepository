package Perl::Dist::WiX:Asset::Launcher;

use Moose;
use MooseX::Types::Moose qw( Str ); 

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has bin => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_bin',
	required => 1,
);

1;
