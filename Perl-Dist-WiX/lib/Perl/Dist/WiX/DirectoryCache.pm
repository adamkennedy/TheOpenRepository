package Perl::Dist::WiX::DirectoryCache;

=pod

=head1 NAME

Perl::Dist::WiX::DirectoryCache - Cache of <Directory> tag objects.

=head1 VERSION

This document describes Perl::Dist::WiX::DirectoryCache version 1.101.

=head1 DESCRIPTION

	# TODO.

=head1 SYNOPSIS

	# TODO.

=head1 INTERFACE

	# TODO.
	
=cut

use 5.008001;
use MooseX::Singleton;
use WiX3::XML::Directory;
use MooseX::AttributeHelpers;

our $VERSION = '1.101_001';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.

has _cache => (
	metaclass => 'Collection::Hash',
	is        => 'rw',
	isa       => 'HashRef[Str]',
	default   => sub { {} },
	provides  => {
		'set'    => '_set_cache_entry',
		'get'    => '_get_cache_entry',
		'exists' => '_exists_cache_entry',
		'delete' => '_delete_cache_entry',
	},
);

sub add_to_cache {
	my $self      = shift;
	my $directory = shift || undef;
	my $fragment  = shift || undef;

	# TODO: If $directory is not a WiX3::XML::Directory, throw an exception.
	# TODO: If the guid exists, throw an exception.

	$self->_set_cache_entry( $directory->get_id(), $fragment->get_id() );

	return;
} ## end sub add_to_cache

sub exists_in_cache {
	my $self = shift;
	my $directory = shift || undef;

	# TODO: If $directory is not a WiX3::XML::Directory, throw an exception.

	return $self->_exists_cache_entry( $directory->get_id() );
}

sub get_previous_fragment {
	my $self = shift;
	my $directory = shift || undef;

	# TODO: If $directory is not a WiX3::XML::Directory, throw an exception.

	return $self->_get_cache_entry( $directory->get_id() );
}

sub delete_cache_entry {
	my $self = shift;
	my $directory = shift || undef;

	# TODO: If $directory is not a WiX3::XML::Directory, throw an exception.

	return $self->_delete_cache_entry( $directory->get_id() );
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
