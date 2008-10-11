package Perl::Dist::WiX::File;

# Represents a <File> tag within the Windows Installer XML Schema

use 5.008;
use Moose;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# WiX <File> Attributes

has id => (
	is  => 'ro',
	isa => 'Str',
);

has source => (
	is  => 'ro',
	isa => 'Str',
);

has name => (
	is  => 'ro',
	isa => 'Str',
);

has short_name => (
	is  => 'ro',
	isa => 'Str',
);

has read_only => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0,
)

1;
