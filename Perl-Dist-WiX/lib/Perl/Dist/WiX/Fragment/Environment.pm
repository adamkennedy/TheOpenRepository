package Perl::Dist::WiX::Fragment::Environment;

####################################################################
# Perl::Dist::WiX::Fragment::Environment - Fragment & Component that contains
#  <Environment> tags
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.008001;
use Moose;
use vars qw( $VERSION );
use WiX3::XML::Environment;

use version; $VERSION = version->new('1.100')->numify;

extends 'WiX3::XML::Fragment';

#>>>
#####################################################################
# Accessors:

has _component => (
	is => 'ro',
	isa => 'WiX3::XML::Component',
	reader => '_get_component',
	init_arg => 'component',
	required => 1,
);

sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' ne ref $_[0] ) {
		$args{'id'} = $_[0];
	} elsif ( 0 == @_ ) {
		$args{'id'} = 'Environment';
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{$_[0]};
	} elsif ( 0 == @_ % 2 ) {
		%args = ( @_ );
	} else {
		# TODO: Throw an error.
	}

	if (not exists $args{'id'}) {
		# TODO: Throw an error.
	}

	my $id = $args{'id'};
	
	my $tag1 = WiX3::XML::Component->new( 
		id => "C_$id"
	);
	my $tag2 = WiX3::XML::DirectoryRef->new( 
		directory_object = Perl::Dist::WiX::DirectoryTree2->get_root(),
		child_tags => [ $tag1 ],
	);
	
	$class->trace_line( 3, "Creating environment fragment.\n" );

	return { 
		id => "Fr_$id",
		child_tags => [ $tag2 ],
		component => $tag1,
	};
}

########################################
# add_entry(...)
# Parameters:
#   Passed to Wix3::XML::Environment->new.
# Returns:
#   Object being called. (chainable)

sub add_entry {
	my $self = shift;

	$self->_get_component()->add_child_tag( WiX3::XML::Environment->new(@_) );

	return $self;
}

1;
