package Perl::Dist::WiX::Component;

# Represents an <Component> tag within the Windows Installer XML Schema

use 5.008;
use Moose;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# WiX <File> Attributes

has id => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has guid => (
	is       => 'ro',
	isa      => 'WinGuid',
	required => 1,
);

has action => (
	is       => 'ro',
	isa      => 'Str',
);

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has part => (
	is       => 'ro',
	isa      => 'Str',
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
