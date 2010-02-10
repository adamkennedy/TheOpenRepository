package Perl::Dist::WiX::Asset::Library;

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str Maybe HashRef );

our $VERSION = '1.102';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has unpack_to => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_unpack_to',
	default => q{},
);

has license => (
	is      => 'ro',
	isa     => Maybe [HashRef],
	reader  => '_get_license',
	default => undef,
);

has install_to => (
	is       => 'ro',
	isa      => HashRef,
	reader   => '_get_install_to',
	required => 1,
);

has build_a => (
	is      => 'ro',
	isa     => HashRef,
	reader  => '_get_build_a',
	default => sub { return {} },
);

sub install {
	my $self = shift;

	my $name = $self->_get_name();
	$self->_trace_line( 1, "Preparing $name\n" );

	# Download the file
	my $tgz =
	  $self->_mirror( $self->_get_url(), $self->_get_download_dir(), );

	# Unpack to the build directory
	my @files;
	my $unpack_to =
	  catdir( $self->_get_build_dir(), $self->_get_unpack_to() );
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}
	@files = $self->_extract( $tgz, $unpack_to );

	# Build the .a file if needed
	my $build_a = $self->_get_build_a();
	if ( defined $build_a ) {

		# Hand off for the .a generation
		push @files,
		  $self->_dll_to_a(
			$build_a->{source}
			? ( source => catfile( $unpack_to, $build_a->{source} ), )
			: (),
			dll => catfile( $unpack_to, $build_a->{dll} ),
			def => catfile( $unpack_to, $build_a->{def} ),
			a   => catfile( $unpack_to, $build_a->{a} ),
		  );
	} ## end if ( defined $build_a )

	# Copy in the files
	my $install_to = $self->_get_install_to();
	if ($install_to) {
		foreach my $k ( sort keys %{$install_to} ) {
			my $from = catdir( $unpack_to, $k );
			my $to = catdir( $self->_get_image_dir(), $install_to->{$k} );
			$self->_copy( $from, $to );
			@files = $self->_copy_filesref( \@files, $from, $to );
		}
	}

	# Copy in licenses
	my $licenses = $self->_get_license();
	if ( defined $licenses ) {
		my $license_dir = $self->_dir('licenses');
		push @files,
		  $self->_extract_filemap( $tgz, $licenses, $license_dir, 1 );
	}

	my @sorted_files = sort { $a cmp $b } @files;
	my $filelist =
	  File::List::Object->new->load_array(@sorted_files)
	  ->filter( $self->_filters )->filter( [$unpack_to] );

	return $filelist;
} ## end sub install

sub _copy_filesref {
	my ( $self, $files_ref, $from, $to ) = @_;

	my @files;

	foreach my $file ( @{$files_ref} ) {
		if ( $file =~ m{\A\Q$from\E}msx ) {
			$file =~ s{\A\Q$from\E}{$to}msx;
		}
		push @files, $file;
	}

	return @files;
} ## end sub _copy_filesref

1;

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Library - "C Library" asset for a Win32 Perl

=head1 SYNOPSIS

  my $library = Perl::Dist::Asset::Library->new(
      name       => 'zlib',
      url        => 'http://strawberryperl.com/packages/zlib-1.2.3.win32.zip',
      unpack_to  => 'zlib',
      build_a    => {
          'dll'    => 'zlib-1.2.3.win32/bin/zlib1.dll',
          'def'    => 'zlib-1.2.3.win32/bin/zlib1.def',
          'a'      => 'zlib-1.2.3.win32/lib/zlib1.a',
      },
      install_to => {
          'zlib-1.2.3.win32/bin'     => 'c/bin',
          'zlib-1.2.3.win32/lib'     => 'c/lib',
          'zlib-1.2.3.win32/include' => 'c/include',
      },
  );

=head1 DESCRIPTION

B<Perl::Dist::WiX::Asset::Library> is a data class that provides encapsulation
and error checking for a "C library" to be installed in a
L<Perl::Dist::WiX>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::WiX> C<install_library>
method (and other things that call it).

B<Perl::Dist::WiX::Asset::Library> is similar to L<Perl::Dist::WiX::Asset::Binary>,
in that it captures a name, source URL, and paths for where to install
files.

It also takes a few more pieces of information to support certain more
esoteric functions unique to C library builds.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::WiX::Role::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::WiX::Role::Asset> and shares its API.

=head2 new

TODO: Document

=head2 install

Installs the library specified by this object. 

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
