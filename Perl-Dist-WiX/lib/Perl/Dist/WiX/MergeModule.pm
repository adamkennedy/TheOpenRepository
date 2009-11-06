package Perl::Dist::WiX::MergeModule;

####################################################################
# Perl::Dist::WiX::MergeModule - <Merge> tag that can create a MergeRef if needed.
#
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#
use 5.008001;
use Moose;
require WiX3::XML::MergeRef;

our $VERSION = '1.100_001';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Merge';

has primary_reference => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
	reader  => '_is_primary_reference',
);

#####################################################################
# Helper routines:

sub get_merge_reference {
	my $self = shift;

	my $primary = $self->_is_primary_reference() ? 'yes' : 'no';
	my $merge_ref =
	  WiX3::XML::MergeRef->new( $self, 'primary' => $primary );

	return $merge_ref;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
