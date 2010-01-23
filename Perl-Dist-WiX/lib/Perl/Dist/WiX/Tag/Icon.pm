package Perl::Dist::WiX::Tag::Icon;

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );

our $VERSION = '1.101_002';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Icon';

has target_type => (
	is => 'bare',
	isa => Str,
	reader => 'get_target_type',
	required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Tag::Icon - <Icon> tag that stores its type of target.

=head1 SYNOPSIS

	my $tag = Perl::Dist::WiX::Tag::Icon->new(
		sourcefile  => catfile($dist->dist_dir(), 'padre.ico'),
		target_type => 'exe',
		id          => 'padre.exe.ico' # I_ is prepended to this.
	);

=head1 DESCRIPTION

This is an XML tag that specifies an icon that is used in a Perl::Dist::WiX 
based distribution.

=head1 METHODS

This class is a L<WiX3::XML::Icon> and inherits its API, so only additional 
API is documented here.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Tag::Icon> object.

If an error occurs, it throws an exception.

It inherits all the parameters described in the 
L<WiX3::XML::Icon> C<new> method documentation, and adds one additional 
parameter.

=over 4

=item target_type

The required string C<target_type> param stores the extension of the target 
of a shortcut icon, or 'msi' if this is the icon for the msi.

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_icon.htm>,

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
