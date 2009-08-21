package Perl::Dist::WiX::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use Moose;
use MooseX::Types::Moose qw( Str HashRef ArrayRef Bool ); 

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has license => (
	is       => 'ro',
	isa      => HashRef,
	reader   => '_get_license',
	required => 1,
);

has patch => (
	is       => 'ro',
	isa      => ArrayRef,
	reader   => '_get_patch',
	required => 1,
);

has unpack_to => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_unpack_to',
	default => q{},
);

has install_to => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_unpack_to',
	required => 1,
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => 'get_force',
	lazy     => 1,
	default  => sub { !! $_[0]->parent->force },
);

sub install {
	# TODO: Throw exception.
}

1;
