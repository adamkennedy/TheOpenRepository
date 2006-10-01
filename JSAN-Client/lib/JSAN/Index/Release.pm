package JSAN::Index::Release;

# See POD at end for docs

use strict;
use File::Spec       ();
use File::Spec::Unix ();
use File::Path       ();
use Params::Util     '_INSTANCE';
use JSAN::Index      ();
use base 'JSAN::Index::Extractable';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';

	# Optional prefork.pm support
	eval "use prefork 'YAML'";
	eval "use prefork 'Archive::Tar'";
	eval "use prefork 'Archive::Zip'";
}

# Make the tar code read saner below
use constant COMPRESSED => 1;

JSAN::Index::Release->table('release');
JSAN::Index::Release->columns( Essential =>
	'id',           # Unique identifier
	'source',       # File path within JSAN   - '/dist/a/ad/adamk/Display.Swap-0.01.tar.gz'
	'distribution', # Distribution            - 'Display.Swap'
	'author',       # The uploading author    - 'ADAMK'
	'version',      # Release version         - '0.01'
	'created',      # Unix time first indexed - '1120886566'
	'doc',          # openjsan.org doc path   - '/doc/a/ad/adamk/Display/Swap/0.01'
	'meta',         # contents of the META.yml file
	'checksum',     # MD5 checksum            - '996156f963ad58c1b55621390e5c2066'
	'latest',       # Most recent release?    - 1
	);
JSAN::Index::Release->columns(
	Primary      => 'id',
	);
JSAN::Index::Release->has_a(
	distribution => 'JSAN::Index::Distribution',
	);
JSAN::Index::Release->has_a(
	author       => 'JSAN::Index::Author',
	);

sub created_string {
	scalar localtime( shift()->created );
}

sub requires {
	my $self = shift;

	# Get the raw dependency hash
	my $meta = $self->meta_data;
	unless ( UNIVERSAL::isa($meta, 'HASH') ) {
		# If it has no META.yml at all, we assume that it
		# has no dependencies.
		return ();
	}
	my $requires = $meta->{requires} or return {};
	if ( UNIVERSAL::isa($requires, 'HASH') ) {
		# To be safe (mainly in case it's a dependency object of
		# some sort) make sure it's a plain hash before returning.
		my %hash = %$requires;
		return \%hash;
	}

	# It could be an array of Requires objects
	if ( UNIVERSAL::isa($requires, 'ARRAY') ) {
		my %hash = ();
		foreach my $dep ( @$requires ) {
			unless ( _INSTANCE($dep, 'Module::META::Requires') ) {
				Carp::croak("Unknown dependency structure in META.yml for "
					. $self->source);
			}
			$hash{ $dep->{name} } = $dep->{version};
		}
		return \%hash;
	}

	Carp::croak("Unknown 'requires' dependency structure in META.yml for "
		. $self->source);
}

sub build_requires {
	my $self = shift;

	# Get the raw dependency hash
	my $meta = $self->meta_data;
	unless ( UNIVERSAL::isa($meta, 'HASH') ) {
		# If it has no META.yml at all, we assume that it
		# has no dependencies.
		return ();
	}
	my $requires = $meta->{build_requires} or return {};
	if ( UNIVERSAL::isa($requires, 'HASH') ) {
		# To be safe (mainly in case it's a dependency object of
		# some sort) make sure it's a plain hash before returning.
		my %hash = %$requires;
		return \%hash;
	}

	# It could be an array of Requires objects
	if ( UNIVERSAL::isa($requires, 'ARRAY') ) {
		my %hash = ();
		foreach my $dep ( @$requires ) {
			unless ( _INSTANCE($dep, 'Module::META::Requires') ) {
				Carp::croak("Unknown dependency structure in META.yml for "
					. $self->source);
			}
			$hash{ $dep->{name} } = $dep->{version};
		}
		return \%hash;
	}

	Carp::croak("Unknown 'build_requires' dependency structure in META.yml for "
		. $self->source);
}

sub requires_libraries {
	my $self     = shift;
	my $requires = $self->requires;

	# Find the library object for each key
	my @libraries = ();
	foreach my $name ( sort keys %$requires ) {
		my $library = JSAN::Index::Library->retrieve( name => $name );
		push @libraries, $library if $library;
	}

	@libraries;
}

sub build_requires_libraries {
	my $self     = shift;
	my $requires = $self->build_requires;

	# Find the library object for each key
	my @libraries = ();
	foreach my $name ( sort keys %$requires ) {
		my $library = JSAN::Index::Library->retrieve( name => $name );
		push @libraries, $library if $library;
	}

	@libraries;
}

sub requires_releases {
	my $self      = shift;
	my @libraries =	$self->requires_libraries;

	# Derive a list of releases
	my @releases = map { $_->release } @libraries;
	return @releases;
}

sub build_requires_releases {
	my $self      = shift;
	my @libraries =	$self->build_requires_libraries;

	# Derive a list of releases
	my @releases = map { $_->release } @libraries;
	return @releases;
}

sub meta_data {
	my $self    = shift;
	require YAML;
	my @structs = YAML::Load($self->meta);
	unless ( defined $structs[0] ) {
		Carp::croak("Failed to load META.yml struct for "
			. $self->source );
	}
	$structs[0];
}

sub mirror {
	my $self     = shift;
	my $location = JSAN::Transport->file_mirror($self->source);
	$location->path;
}

sub file_mirrored {
	!! -f $_[0]->file_path;
}


sub file_path {
	JSAN::Transport->file_location($_[0]->source)->path;
}

sub archive {
	# Cache result of the real method
	$_[0]->{archive} or
	$_[0]->{archive} = $_[0]->_archive;
}

sub _archive {
	my $self = shift;

	# Load tarballs
	if ( $self->source =~ /\.tar\.gz/ ) {
		require Archive::Tar;
		my $tar  = Archive::Tar->new;
		my $path = $self->mirror;
		$tar->read($path, COMPRESSED)
			or Carp::croak("Failed to open tarball '$path'");
		return $tar;
	}

	# Load zip files
	if ( $self->source =~ /\.zip$/ ) {
		require Archive::Zip;
		my $zip  = Archive::Zip->new;
		my $path = $self->mirror;
		unless ( $zip->read($path) == Archive::Zip::AZ_OK() ) {
			Carp::croak("Failed to open zip file '$path'");
		}
		return $zip;
	}

	# We don't support anything else
	Carp::croak('Failed to load unsupported archive type '
		. $self->source);
}

sub extract_libs {
	my $self = shift;
	$self->extract_resource('lib', @_ );
}

sub extract_resource {
	my $self     = shift;
	my $resource = shift
		or Carp::croak("No resource name provided to _extract_resource");
	my %params   = @_;

	# Check the extraction destination
	$params{to} ||= File::Spec->curdir;
	unless ( -d $params{to} ) {
		Carp::croak("Extraction directory '$params{to}' does not exist");
	}
	unless ( -w $params{to} ) {
		Carp::croak("No permissions to write to extraction directory '$params{to}'");
	}

	# Split on archive type
	if ( $self->archive->isa('Archive::Tar') ) {
		return $self->_extract_resource_from_tar($resource, @_);
	}
	if ( $self->archive->isa('Archive::Zip') ) {
		return $self->_extract_resource_from_zip($resource, @_);
	}
	Carp::croak("Unsupported archive type " . ref($self->archive));
}





#####################################################################
# Support Methods

sub _extract_resource_from_tar {
	my ($self, $resource, %params) = @_;
	my $tar   = $self->archive;
	my @files = $tar->get_files;

	# Determine which files to extract, and to where
	my $extracted_files = 0;
	foreach my $item ( @files ) {
		next unless $item->is_file;

		# Split into parts and remove the top level dir
		my ($vol, $dir, $file)
			= File::Spec::Unix->splitpath($item->name);
		my @dirs = File::Spec::Unix->splitdir($dir);
		shift @dirs;

		# Is this file in the resource directory
		my $res = shift(@dirs) or next;
		next unless $res eq $resource;

		# These are STILL relative, but we'll deal with that later.
		my $write_dir = File::Spec->catfile($params{to}, @dirs);

		# Write the file
		$self->_write( $write_dir, $file, $item->get_content );
		$extracted_files++;
	}

	# Return the number of files, or error if none
	return $extracted_files if $extracted_files;
	my $path = $self->source;
	Carp::croak("Tarball '$path' does not contain resource '$resource'");
}

sub _extract_resource_from_zip {
	Carp::croak("Zip support not yet completed");
}

sub _write {
	my ($self, $dir, $file, $content) = @_;

	# Localise newlines in the files
	$content =~ s/(\015{1,2}\012|\015|\012)/\n/g;

	# Create the save directory if needed
	File::Path::mkpath( $dir, 0, 0755 ) unless -d $dir;

	# Save it
	my $path = File::Spec->catfile( $dir, $file );
	open( LIBRARY, '>', $path ) 
		or Carp::croak( "Failed to open '$path' for writing: $!" );
	print LIBRARY $content
		or Carp::croak( "Failed to write to '$path'" );
	close LIBRARY
		or Carp::croak( "Failed to close '$path' after writing" );

	1;
}

1;

__END__

=pod

=head1 NAME

JSAN::Index::Release - A JavaScript Archive Network (JSAN) Release

=head1 DESCRIPTION

This class provides objects for a single release of a distribution by an author

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, it has the
following methods

=head2 id

The C<id> accessor returns the unique identifier for the release (an integer)

=head2 source

The C<source> access returns the root-relative path within a JSAN mirror
that the package can be found at.

=head2 distribution

The C<distribution> method returns the L<JSAN::Index::Distribution> for
the distribution that this release is of.

=head2 author

The C<author> method returns the L<JSAN::Index::Author> for the JSAN author
that uploaded the release.

=head2 version

The C<version> accessor returns the version of the release.

=head2 created

The C<created> accessor returns the time that the release was received and
first indexed by the JSAN upload server.

Returns an integer in unix epoch time.

=head2 created_string

The C<created_string> method returns the time that the release was recieved
and first indexed by the JSAN upload server.

Is equivalent to C<scalar localtime $object-E<gt>created>.

Returns a time as a localtime string.

=head2 doc

The C<doc> accessor returns the root-relative location of the documentation
for this release on the L<http://openjsan.org/> website.

=head2 meta

The C<meta> accessor returns the actual content of the C<META.yml> file that
came with the distribution.

=head2 meta_data

The C<meta_data> method loads and deserialises the META.yml content
contained in the index (and returned by the C<meta> method above).

=head2 checksum

The C<checksum> accessor returns the MD5 checksum for the release tarball.

=head2 latest

The C<latest> accessor returns a boolean flag indicating if the release is
the most recent release of the distribution.

=head2 requires

The C<requires> method finds the set of run-time library dependencies for
this release, as identified in the META.yml data contained in the index.

Returns a reference to a HASH where the key is the name of a library as
a string, and the value is the version for the dependency (or zero if the
dependency is not for a specific version).

=head2 requires_libraries

The C<requires_libraries> method returns a list of the C<JSAN::Index::Library>
dependencies as identified by the META.yml file for the release.

=head2 requires_releases

The C<requires_releases> method returns a list of the C<JSAN::Index::Release>
dependencies based on the dependencies specified in the META.yml file for the
release.

=head2 build_requires

The C<build_requires> method finds the set of build-time library
dependencies for this release, as identified in the META.yml data contained
in the index.

Returns a reference to a HASH where the key is the name of a library as
a string, and the value is the version for the dependency (or zero if the
dependency is not for a specific version).

=head2 build_requires_libraries

The C<build_requires_libraries> method returns a list of the build-time
C<JSAN::Index::Library> dependencies as identified by the META.yml file
for the release.

=head2 build_requires_releases

The C<requires_releases> method returns a list of the C<JSAN::Index::Release>
build-time depedencies based on those specified in the META.yml file for the
release.

=head2 file_path

The C<file_path> method returns the location on the local disk where
the release tarball should be, if mirrored.

=head2 mirror

The C<mirror> method fetches the tarball from your JSAN currently configured
JSAN mirror as determined by L<JSAN::Transport> (if not already cached).

Returns a file path to the tarball on the local machine, or may emit an
exception thrown by the underlying L<JSAN::Transport> functions.

=head2 file_mirrored

The C<file_mirrored> method checks to see if the release tarball has previously
been downloaded to the local mirror.

Returns true if the file exists in the local mirror, or false if not.

=head2 archive

The C<archive> method returns the release as an in-memory archive.
Depending on the type, this should be either a L<Archive::Tar> or an
L<Archive::Zip> object.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Client>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<JSAN::Index>, L<JSAN::Shell>, L<http://openjsan.org>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
