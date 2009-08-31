package Perl::Dist::WiX::Icon;

#####################################################################
# Perl::Dist::WiX::Icon - Extends <Icon> tags to make them searchable 
# easily by Perl::Dist::WiX::IconArray.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Icon';

has target_type => (
	is => 'ro',
	isa => Str,
	reader => 'get_target_type',
	required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;