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
use vars                 qw( $VERSION );
use MooseX::Types::Moose qw( Str      );

use version; $VERSION = version->new('1.100')->numify;

extends 'WiX3::XML::Icon';

has target_type => (
	is => 'ro',
	isa => Str,
	reader => 'get_target_type',
	required => 1,
);

1;