package Perl::Dist::WiX::FeatureTree2;

=pod

=head1 NAME

Perl::Dist::WiX::FeatureTree2 - Tree of <Feature> tag objects.

=head1 VERSION

This document describes Perl::Dist::WiX::FeatureTree2 version 1.102.

=head1 DESCRIPTION

	# TODO.

=head1 SYNOPSIS

	# TODO.

=head1 INTERFACE

	# TODO.
	
=cut

use 5.008001;
use Moose 0.90;
require WiX3::XML::Feature;

our $VERSION = '1.102';
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

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
