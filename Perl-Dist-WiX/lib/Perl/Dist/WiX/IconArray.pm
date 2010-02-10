package Perl::Dist::WiX::IconArray;

=pod

=head1 NAME

Perl::Dist::WiX::IconArray - A list of <Icon> tags.

=head1 VERSION

This document describes Perl::Dist::WiX::IconArray version 1.102.

=head1 DESCRIPTION

	# TODO: Document

=head1 SYNOPSIS

	# TODO: Document

=head1 INTERFACE

	# TODO: Document
	
=cut

use 5.008001;
use Moose 0.90;
use Params::Util qw( _STRING   );
use File::Spec::Functions qw( splitpath );
require Perl::Dist::WiX::Tag::Icon;

our $VERSION = '1.102002';
$VERSION =~ s/_//ms;

has _icon => (
	traits    => ['Array'],
	is        => 'rw',
	isa       => 'ArrayRef[Perl::Dist::WiX::Tag::Icon]',
	default   => sub { [] },
	handles  => {
		'_push_icon'      => 'push',
		'_count_icons'    => 'count',
		'_get_icon_array' => 'elements',
	},
);



#####################################################################
# Main Methods

########################################
# add_icon($pathname_icon, $pathname_target)
# Parameters:
#   $pathname_icon: Path of icon.
#   $pathname_target: Path of icon's target.
# Returns:
#   Id of icon.

sub add_icon {
	my ( $self, $pathname_icon, $pathname_target ) = @_;

	# Check parameters
	unless ( defined $pathname_target ) {
		$pathname_target = 'Perl.msi';
	}
	unless ( defined _STRING($pathname_target) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_target',
			where     => '::IconArray->add_icon'
		);
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::IconArray->add_icon'
		);
	}

	# Find the type of target.
	my ($target_type) = $pathname_target =~ m{\A.*[.](.+)\z}msx;

# TODO: Make this work.
#	$self->trace_line( 2,
#		"Adding icon $pathname_icon with target type $target_type.\n" );

	# If we have an icon already, return it.
	my $icon = $self->search_icon( $pathname_icon, $target_type );
	if ( defined $icon ) { return $icon; }

	# Get Id made.
	my ( undef, undef, $filename_icon ) = splitpath($pathname_icon);
	my $id = substr $filename_icon, 0, -4;
	$id =~ s/[^A-Za-z0-9]/_/gmxs;      # Substitute _ for anything
	                                   # non-alphanumeric.
	$id .= ".$target_type.ico";

	# Add icon to our list.
	$self->_push_icon(
		Perl::Dist::WiX::Tag::Icon->new(
			sourcefile  => $pathname_icon,
			target_type => $target_type,
			id          => $id
		) );

	return $id;
} ## end sub add_icon

########################################
# search_icon($pathname_icon, $target_type)
# Parameters:
#   $pathname_icon: Path of icon to search for.
#   $target_type: Target type to search for.
# Returns:
#   Id of icon.

sub search_icon {
	## no critic (ProhibitExplicitReturnUndef)
	my ( $self, $pathname_icon, $target_type ) = @_;

	# Check parameters
	unless ( defined $target_type ) {
		$target_type = 'msi';
	}
	unless ( defined _STRING($target_type) ) {
		PDWiX::Parameter->throw(
			parameter => 'target_type',
			where     => '::IconArray->search_icon'
		);
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::IconArray->search_icon'
		);
	}

	if ( 0 == $self->_count_icons() ) { return undef; }

	# Print each icon
	foreach my $icon ( $self->_get_icon_array() ) {
		if (    ( $icon->get_sourcefile eq $pathname_icon )
			and ( $icon->get_target_type eq $target_type ) )
		{
			return $icon->get_id;
		}
	}

	return undef;
} ## end sub search_icon


########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Icon> tags defined by this object.

sub as_string {
	my $self = shift;
	my $answer;

	# Short-circuit
	if ( 0 == $self->_count_icons ) { return q{}; }

	# Print each icon
	foreach my $icon ( $self->_get_icon_array() ) {
		my $id   = $icon->get_id();
		my $file = $icon->get_sourcefile();
		$answer .= "    <Icon Id='I_$id' SourceFile='$file' />\n";
	}

	return $answer;
} ## end sub as_string

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
