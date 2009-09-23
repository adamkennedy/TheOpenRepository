package JSAN::Index::Release;

# See POD at end for docs

use strict;
use warnings;
use Carp                      ();
use File::Spec                ();
use File::Spec::Unix          ();
use File::Path                ();
use Params::Util              ();
use JSAN::Index::Extractable  ();
use JSAN::Index::Distribution ();
use JSAN::Index::Author       ();

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.16';
    @ISA     = 'JSAN::Index::Extractable';

    # Optional prefork.pm support
    eval "use prefork 'YAML'";
    eval "use prefork 'Archive::Tar'";
    eval "use prefork 'Archive::Zip'";
}

# Make the tar code read saner below
use constant COMPRESSED => 1;

sub fetch_distribution {
    JSAN::Index::Distribution->retrieve(
        name => $_[0]->distribution,
    );
}

sub fetch_author {
    JSAN::Index::Author->retrieve(
        login => $_[0]->author,
    );
}

sub retrieve {
    my $class  = shift;
    my %params = @_;
    my $sql    = join " and ", map { "$_ = ?" } keys(%params); 
    my @result = $class->select( "where $sql", values(%params) );
    if ( @result == 1 ) {
        return $result[0];
    }
    if ( @result > 1 ) {
        Carp::croak("Found more than one author record");
    } else {
        return undef;
    }
}


sub retrieve_all {
    my $class  = shift;
    
    return $class->select()
}


sub file_path {
    JSAN::Transport->file_location($_[0]->source)->path;
}

sub file_mirrored {
    !! -f $_[0]->file_path;
}

sub mirror {
    my $self     = shift;
    my $location = JSAN::Transport->file_mirror($self->source);
    $location->path;
}

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
            unless ( Params::Util::_INSTANCE($dep, 'Module::META::Requires') ) {
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
            unless ( Params::Util::_INSTANCE($dep, 'Module::META::Requires') ) {
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
    my @libraries = $self->requires_libraries;

    # Derive a list of releases
    my @releases = map { $_->fetch_release } @libraries;
    return @releases;
}

sub build_requires_releases {
    my $self      = shift;
    my @libraries = $self->build_requires_libraries;

    # Derive a list of releases
    my @releases = map { $_->fetch_release } @libraries;
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
    unless ( open( LIBRARY, '>', $path ) ) {
        Carp::croak( "Failed to open '$path' for writing: $!" );
    }
    unless ( print LIBRARY $content ) {
        Carp::croak( "Failed to write to '$path'" );
    }
    unless ( close LIBRARY ) {
        Carp::croak( "Failed to close '$path' after writing" );
    }

    1;
}





######################################################################
# Generated by ORLite 1.25 (Unused parts are commented out)

#sub base { 'JSAN::Index' }
#
#sub table { 'release' }

sub select {
    my $class = shift;
    my $sql   = 'select "id", "distribution", "author", "checksum", "created", "doc", "meta", "latest", "source", "srcdir", "version" from release ';
       $sql  .= shift if @_;
    my $rows  = JSAN::Index->selectall_arrayref( $sql, { Slice => {} }, @_ );
    bless( $_, 'JSAN::Index::Release' ) foreach @$rows;
    wantarray ? @$rows : $rows;
}

#sub count {
#    my $class = shift;
#    my $sql   = 'select count(*) from release ';
#       $sql  .= shift if @_;
#    JSAN::Index->selectrow_array( $sql, {}, @_ );
#}
#
#sub iterate {
#    my $class = shift;
#    my $call  = pop;
#    my $sql   = 'select "id", "distribution", "author", "checksum", "created", "doc", "meta", "latest", "source", "srcdir", "version" from release ';
#       $sql  .= shift if @_;
#    my $sth   = JSAN::Index->prepare( $sql );
#    $sth->execute( @_ );
#    while ( $_ = $sth->fetchrow_hashref ) {
#        bless( $_, 'JSAN::Index::Release' );
#        $call->() or last;
#    }
#    $sth->finish;
#}

sub id {
    $_[0]->{id};
}

sub distribution {
    $_[0]->{distribution};
}

sub author {
    $_[0]->{author};
}

sub checksum {
    $_[0]->{checksum};
}

sub created {
    $_[0]->{created};
}

sub doc {
    $_[0]->{doc};
}

sub meta {
    $_[0]->{meta};
}

sub latest {
    $_[0]->{latest};
}

sub source {
    $_[0]->{source};
}

sub srcdir {
    $_[0]->{srcdir};
}

sub version {
    $_[0]->{version};
}

1;

__END__

=head1 NAME

JSAN::Index::Release - JSAN::Index class for the release table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = JSAN::Index::Release->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = JSAN::Index::Release->select(
      'where id > ? order by id',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
release table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM release> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<JSAN::Index::Release> objects when called in list context, or a
reference to an C<ARRAY> of B<JSAN::Index::Release> objects when called in scalar
 context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = JSAN::Index::Release->count;
  
  # How many objects 
  my $small = JSAN::Index::Release->count(
      'where id > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
release table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM release> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head1 ACCESSORS

=head2 id

  if ( $object->id ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The release table was originally created with the
following SQL command.

  CREATE TABLE release (
      id INTEGER PRIMARY KEY NOT NULL,
      distribution varchar (
          100
      )
      NOT NULL,
      author varchar (
          100
      )
      NOT NULL,
      checksum varchar (
          100
      )
      NOT NULL,
      created varchar (
          100
      )
      NOT NULL,
      doc varchar (
          100
      )
      NOT NULL,
      meta text,
      latest int (
          11
      )
      NOT NULL,
      source varchar (
          100
      )
      NOT NULL,
      srcdir varchar (
          100
      )
      NOT NULL,
      version varchar (
          100
      )
  )


=head1 SUPPORT

JSAN::Index::Release is part of the L<JSAN::Index> API.

See the documentation for L<JSAN::Index> for more information.

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

