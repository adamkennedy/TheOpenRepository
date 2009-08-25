package Perl::Dist::WiX::Fragment::Files;

#####################################################################
# Perl::Dist::WiX::Fragment::Files - A <Fragment> and <DirectoryRef> tag that
# contains <Directory> or <DirectoryRef> elements, which contain <Component> and 
# <File> tags.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Bool );
use WiX3::Exceptions;
use File::List::Object;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Fragment';

has files => (
	is => 'ro',
	isa	=> 'File::List::Object',
	required => 1,
	reader => 'get_files',
	handles => [ 'add_files' ],
);

has can_overwrite => (
	is => 'ro',
	isa => Bool,
	default => 0,
	reader => 'can_overwrite',
);

# This type of fragment needs regeneration.
sub regenerate {
	WiX3::Exception::Unimplemented->throw();

	return;
}

sub check_duplicates {
	my $self = shift;
	my $filelist = shift;

	if (not $self->can_overwrite()) {
		return 1;
	}
	
	# TODO: Implement later.
	# PDWiX::Unimplemented->throw('Perl::Dist::WiX::Fragment::Files->check_duplicates');
	return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;