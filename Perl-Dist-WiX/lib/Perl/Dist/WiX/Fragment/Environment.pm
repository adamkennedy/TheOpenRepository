package Perl::Dist::WiX::Fragment::Environment;

####################################################################
# Perl::Dist::WiX::Fragment::Environment - Fragment & Component that contains
#  <Environment> tags
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose;
use WiX3::XML::Environment;

our $VERSION = '1.100';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

extends 'WiX3::XML::Fragment';

#####################################################################
# Accessors:

has component => (
	is       => 'ro',
	isa      => 'WiX3::XML::Component',
	reader   => '_get_component',
	required => 1,
);

sub BUILDARGS {
	my $class = shift;
	my %args;

	## no critic(CascadingIfElse)
	if ( @_ == 1 && !ref $_[0] ) {
		$args{'id'} = $_[0];
	} elsif ( 0 == @_ ) {
		$args{'id'} = 'Environment';
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw(
'Parameters incorrect (not a hashref, hash, or id) for ::Fragment::Environment'
		);
	}

	my $id;

	if ( not exists $args{'id'} ) {
		$id = 'Environment';
	} else {
		$id = $args{'id'};
	}

	my $tag1 = WiX3::XML::Component->new( id => $id );

	return {
		id        => $id,
		component => $tag1,
	};
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	my $tag2 =
	  WiX3::XML::DirectoryRef->new( directory_object =>
		  Perl::Dist::WiX::DirectoryTree2->instance()->get_root(), );
	$tag2->add_child_tag( $self->_get_component() );

	$self->add_child_tag($tag2);
	$self->trace_line( 3, "Creating environment fragment.\n" );

	return;
} ## end sub BUILD

########################################
# add_entry(...)
# Parameters:
#   Passed to Wix3::XML::Environment->new.
# Returns:
#   Object being called. (chainable)

sub add_entry {
	my $self = shift;

	$self->_get_component()
	  ->add_child_tag( WiX3::XML::Environment->new(@_) );

	return $self;
}

sub get_entries_count {
	my $self = shift;

	return $self->_get_component()->count_child_tags();

}

# No duplicates will be here to check.
sub check_duplicates {
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
