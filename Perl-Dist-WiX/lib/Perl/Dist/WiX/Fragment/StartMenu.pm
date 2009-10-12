package Perl::Dist::WiX::Fragment::StartMenu;

#####################################################################
# Perl::Dist::WiX::Fragment::StartMenu - A <Fragment> and <DirectoryRef> tag that
# contains <Icon> elements.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#
use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str Bool );
use WiX3::Exceptions;
require Perl::Dist::WiX::IconArray;
require Perl::Dist::WiX::DirectoryTree2;
require WiX3::XML::Component;
require WiX3::XML::CreateFolder;
require WiX3::XML::RemoveFolder;
require WiX3::XML::DirectoryRef;
require WiX3::XML::Shortcut;

our $VERSION = '1.100';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

extends 'WiX3::XML::Fragment';

has icons => (
	is      => 'ro',
	isa     => 'Perl::Dist::WiX::IconArray',
	default => sub { return Perl::Dist::WiX::IconArray->new() },
	reader  => 'get_icons',
);

has directory_id => (
	is       => 'ro',
	isa      => Str,
	required => 1,
	reader   => 'get_directory_id',
);

has root => (
	is       => 'ro',
	isa      => 'Perl::Dist::WiX::DirectoryRef',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build_root',
	reader   => '_get_root',
);

sub BUILDARGS {
	my $class = shift;
	my %args;

	## no critic(ProhibitCascadingIfElse)
	if ( @_ == 1 && 'HASH' ne ref $_[0] ) {
		$args{'id'} = $_[0];
	} elsif ( 0 == @_ ) {
		$args{'id'} = 'StartMenuIcons';
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw(
'Parameters incorrect (not a hashref, hash, or id) for ::Fragment::StartMenu'
		);
	}

	if ( not exists $args{'id'} ) {
		$args{'id'} = 'StartMenuIcons';
	}

	return \%args;
} ## end sub BUILDARGS

sub _build_root {
	my $self = shift;
	my $tree = Perl::Dist::WiX::DirectoryTree2->instance();

	my $id        = $self->get_directory_id();
	my $directory = $tree->get_directory_object($id);
	if ( not defined $directory ) {
		PDWiX->throw("Could not find directory object for id $id");
	}

	my $remove = WiX3::XML::RemoveFolder->new(
		id => 'RemoveStartMenuFolder',
		on => 'uninstall',
	);
	my $remove_component =
	  WiX3::XML::Component->new( id => 'RemoveStartMenuFolder', );
	my $root = Perl::Dist::WiX::DirectoryRef->new($directory);

	$remove_component->add_child_tag($remove);
	$root->add_child_tag($remove_component);
	$self->add_child_tag($root);

	return $root;
} ## end sub _build_root

# Takes hash only at present.
sub add_shortcut {
	my $self = shift;
	my %args = @_;

	# TODO: Validate arguments.

	$args{id} =~ s{[^A-Za-z0-9]}{_}msgx;

	my $component = WiX3::XML::Component->new( id => "S_$args{id}" );
	my $shortcut = WiX3::XML::Shortcut->new(
		id               => "$args{id}",
		name             => $args{name},
		description      => $args{description},
		target           => $args{target},
		icon             => "I_$args{icon_id}",
		workingdirectory => "D_$args{working_dir}",
	);

	$component->add_child_tag($shortcut);

	my $cf =
	  WiX3::XML::CreateFolder->new(
		directory => $self->get_directory_id() );
	$component->add_child_tag($cf);

	$self->_get_root()->add_child_tag($component);

	return;
} ## end sub add_shortcut

# The fragment is already generated. No need to regenerate.
sub regenerate {
	return;
}

# No duplicates will be here to check.
sub check_duplicates {
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
