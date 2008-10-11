package Perl::Dist::WiX::Environment;

# Represents an <Environment> tag within the Windows Installer XML Schema

use 5.008;
use Moose;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# WiX <File> Attributes

has id => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has action => (
	is       => 'ro',
	isa      => enum([qw{ create set remove }]),
	required => 1,
);

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has part => (
	is       => 'ro',
	isa      => enum([qw{ all first last }]),
	required => 1,
);

has permanent => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
	default  => 0,
);

has system => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
	default  => 0,
);

has value => (
	is       => 'ro',
	isa      => 'String',
);

__PACKAGE__->meta->make_immutable;

1;
