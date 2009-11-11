package Perl::Dist::WiX::Asset::File;

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catfile );
require File::Remove;
require File::List::Object;

our $VERSION = '1.101_001';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

with 'Perl::Dist::WiX::Role::Asset';

has install_to => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_install_to',
	required => 1,
);

sub install {
	my $self = shift;

	my $download_dir = $self->_get_download_dir();
	my $image_dir    = $self->_get_image_dir();
	my @files;


	# Get the file
	my $tgz = $self->_mirror( $self->_get_url, $download_dir );

	# Copy the file to the target location
	my $from = catfile( $download_dir, $self->_get_file );
	my $to   = catfile( $image_dir,    $self->_get_install_to );
	unless ( -f $to ) {
		push @files, $to;
	}

	$self->_copy( $from => $to );

	# Clear the download file
	File::Remove::remove( \1, $tgz );

	my $filelist =
	  File::List::Object->new->load_array(@files)
	  ->filter( $self->_filters );

	return $filelist;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::File - "Single File" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::File->new(
      url        => 'http://host/path/file',
      install_to => 'perl/foo.txt',
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::File> is a data class that provides encapsulation
and error checking for a single file to be installed unmodified into a
L<Perl::Dist::WiX>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::WiX> C<install_file>
method (and other things that call it).

This asset exists to allow for cases where very small tweaks need to be
done to distributions by dropping in specific single files.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::WiX::Role::Asset>.

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset> and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::File> object.

It inherits all the params described in the L<Perl::Dist::WiX::Role::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item install_to

The required C<install_to> param describes the location that the package
will be installed to.

The C<install_to> param should be a simple string that represents the
entire destination path (including file name).

=back

The C<new> constructor returns a B<Perl::Dist::Asset::WiX::File> object,
or throws an exception (dies) if an invalid param is provided.

=head2 install

The C<install> method installs the file in the specified place.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Perl::Dist::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
