package Perl::Dist::WiX::FeatureTree2;

####################################################################
# Perl::Dist::WiX::FeatureTree2 - Tree of MSI features.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose 0.90;
require WiX3::XML::Feature;

our $VERSION = '1.101_001';
$VERSION =~ s/_//ms;

#####################################################################
# Accessors:

has parent => (
	is       => 'ro',
	isa      => 'Perl::Dist::WiX',
	weak_ref => 1,
	handles  => {
		'_app_ver_name'   => 'app_ver_name',
		'_feature_tree'   => 'msi_feature_tree',
		'_get_components' => 'get_component_array',
		'_trace_line'     => 'trace_line',
	},
);

has features => (
	traits   => ['Array'],
	is       => 'ro',
	isa      => 'ArrayRef[WiX3::XML::Feature]',
	default  => sub { [] },
	init_arg => undef,
	handles  => {
		'_push_feature'      => 'push',
		'_count_features'    => 'count',
		'_get_feature'       => 'get',
		'_get_feature_array' => 'elements',
	},
);


#####################################################################
# Constructor for FeatureTree2
#

sub BUILD {
	my $self = shift;
	my $feat;

	# Start the tree.
	$self->_trace_line( 0, "Creating feature tree...\n" );
	if ( defined $self->_feature_tree() ) {
		PDWiX->throw( 'Complex feature tree not implemented in '
			  . "Perl::Dist::WiX $VERSION." );
	} else {
		$feat = WiX3::XML::Feature->new(
			id          => 'Complete',
			title       => $self->_app_ver_name(),
			description => 'The complete package.',
			level       => 1,
		);
		$feat->add_child_tag( $self->_get_components() );
		$self->_push_feature($feat);
	}

	return;
} ## end sub BUILD

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representing features contained in this object.

sub as_string {
	my $self = shift;

	# Get the strings for each of our branches.
	my $spaces = q{    };              # Indent 4 spaces.
	my $answer = $spaces;
	foreach my $feature ( $self->_get_feature_array() ) {
		$answer .= $feature->as_string;
	}

	chomp $answer;
#<<<
	$answer =~ s{\n}                   # match a newline 
				{\n$spaces}gxms;       # and add spaces after it.
									   # (i.e. the beginning of the line.)
#>>>

	return $answer;
} ## end sub as_string

sub as_string_msm {
	my $self = shift;

	# Get the strings for each of our branches.
	my $spaces = q{    };              # Indent 4 spaces.
	my $answer = $spaces;
	foreach my $feature ( $self->_get_feature_array() ) {

		# We just want the children for this one.
		$answer .= $feature->as_string_children;
	}

	chomp $answer;
#<<<
	$answer =~ s{\n}                   # match a newline 
				{\n$spaces}gxms;       # and add spaces after it.
									   # (i.e. the beginning of the line.)
#>>>

	return $answer;
} ## end sub as_string_msm

sub add_merge_module {
	my $self  = shift;
	my $mm    = shift;
	my $index = shift || 0;

	my $feature = $self->_get_feature($index);
	$feature->add_child_tag( $mm->get_merge_reference() );

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
