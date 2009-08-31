package Perl::Dist::WiX::Asset::Binary;

use Moose;
use MooseX::Types::Moose qw( Str HashRef Maybe ); 
use File::Spec::Functions qw( catdir );

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has install_to => (
	is       => 'ro',
	isa      => Str | HashRef,
	reader   => '_get_install_to',
	default => 'c',
);

has license => (
	is       => 'ro',
	isa      => Maybe[HashRef],
	reader   => '_get_license',
	default  => undef,
);

sub install {
	my $self   = shift;
	
	my $name = $self->_get_name();
	$self->_trace_line( 1, "Preparing $name\n" );

	# Download the file
	my $tgz = $self->_mirror( $self->_get_url, $self->_get_download_dir, );

	# Unpack the archive
	my @files;
	my $install_to = $self->_get_install_to();
	if ( ref $install_to eq 'HASH' ) {
		@files =
		  $self->_extract_filemap( $tgz, $install_to,
			$self->_get_image_dir );

	} elsif ( !ref $install_to ) {

		# unpack as a whole
		my $tgt = catdir( $self->_get_image_dir(), $install_to );
		@files = $self->_extract( $tgz, $tgt );
	}

	# Find the licenses
	my $licenses = $self->_get_license();
	if ( defined $licenses ) {
		push @files,
		  $self->_extract_filemap( $tgz, $licenses,
			$self->_get_license_dir, 1 );
	}

	my $filelist =
	  File::List::Object->new()->load_array(@files)->filter( $self->_filters );

	return $filelist;
} ## end sub install_binary

no Moose;
__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=head1 NAME

Perl::Dist::Asset::Binary - "Binary Package" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::Binary->new(
      name       => 'dmake',
      license    => {
          'dmake/COPYING'            => 'dmake/COPYING',
          'dmake/readme/license.txt' => 'dmake/license.txt',
      },
      install_to => {
          'dmake/dmake.exe' => 'c/bin/dmake.exe',	
          'dmake/startup'   => 'c/bin/startup',
      },
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::Binary> is a data class that provides encapsulation
and error checking for a "binary package" to be installed in a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::Inno> C<install_binary>
method (and other things that call it).

These packages will be simple zip or tar.gz files that are local files,
installed in a CPAN distribution's 'share' directory, or retrieved from
the internet via a URI.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut






#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::Binary> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the logical (arbitrary) name of the package
for the purposes of identification.

=item license

During the installation build process, licenses files are pulled from
the various source packages and written to a single dedicated directory.

The optional C<license> param should be a reference to a HASH, where the keys
are the location of license files within the package, and the values are
locations within the "licenses" subdirectory of the final installation.

=item install_to

The required C<install_to> param describes the location that the package
will be installed to.

If the C<install_to> param is a single string, such as "c" or "perl\foo"
the entire binary package will be installed, with the root of the package
archive being placed in the directory specified.

If the C<install_to> param is a reference to a HASH, it is taken to mean
that only some parts of the original binary package are required in the
final install. In this case, the keys should be the file or directories
desired, and the values are the names of the file or directory in the
final Perl installation.

Although this param does not default when called directly, in practice
the L<Perl::Dist::Inno> C<install_binary> method will default this value
to "c", as most binary installations are for C toolchain tools or 
pre-compiled C libraries.

=back

The C<new> constructor returns a B<Perl::Dist::Asset::Binary> object,
or throws an exception (dies) if an invalid param is provided.

=cut


=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
