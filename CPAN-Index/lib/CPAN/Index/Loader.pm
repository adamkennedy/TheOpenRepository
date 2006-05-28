package CPAN::Index::Loader;

=pod

=head1 NAME

CPAN::Index::Loader - Populates the CPAN index SQLite database

=head1 DESCRIPTION

This package implements all the functionality required to download
the CPAN index data, parse it, and populate the SQLite database
file.

Because it involves loading a number of otherwise unneeded modules,
this package is B<not> loaded by default with the rest of
L<CPAN::Index>, but may be loaded on-demand if needed.

=head1 METHODS

=cut

use strict;
use Carp           ();
use Params::Util   qw{ _INSTANCE };
use Email::Address ();
use CPAN::Cache    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $loader = CPAN::Index::Loader->new(
      remote_uri => 'http://search.cpan.org/CPAN',
      local_dir  => '/tmp/cpanindex',
      );

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create the cache object
	unless ( $self->cache ) {
		my @params = ();
		$self->{cache} = CPAN::Cache->new(
			remote_uri => delete($self->{remote_uri}),
			local_dir  => delete($self->{local_dir}),
			trace      => $self->{trace},
			verbose    => $self->{verbose},
			);
	}
			
}

=pod

=head2 cache

The C<cache> accessor returns a L<CPAN::Cache> object that represents the
CPAN cache.

=cut

sub cache {
	$_[0]->{cache};
}

=pod

=head2 remote_uri

The C<remote_uri> accessor return a L<URI> object for the location of the
CPAN mirror.

=cut

sub remote_uri {
	$_[0]->cache->remote_uri;
}

=pod

=head2 local_dir

The C<local_dir> accessor returns the filesystem path for the root directory
of the local CPAN file cache.

=cut

sub local_dir {
	$_[0]->cache->local_dir;
}





#####################################################################
# Main Methods

=pod

=head2 load_files

TO DO

=cut





#####################################################################
# Parsing Methods

=pod

=head2 load_authors

  CPAN::Index::Loader->load_authors( $schema, $handle );

The C<load_authors> method populates the C<package> table from the CPAN
F<01mailrc.txt.gz> file.

The C<author> table in the SQLite database should already be empty
B<before> this method is called.

Returns the number of authors added to the database, or throws an
exception on error.

=cut

sub load_authors {
	my $self   = shift;
	my $schema = _INSTANCE(shift, 'DBIx::Class::Schema')
		or Carp::croak("Did not provide a DBIx::Class::Schema param");
	my $handle = _INSTANCE(shift, 'IO::Handle')
		or Carp::croak("Did not provide an IO::Handle param");

	# Process the author records
	my $created = 0;
	while ( my $line = $handle->getline ) {
		# Parse the line
		unless ( $line =~ /^alias\s+(\S+)\s+\"(.+)\"[\012\015]+$/ ) {
			Carp::croak("Invalid 01mailrc.txt.gz line '$line'");
		}
		my $id    = $1;
		my $email = $2;

		# Parse the full email address to seperate the parts
		my @found = Email::Address->parse($email);
		unless ( @found == 1 ) {
			Carp::croak("Failed to correctly parse email address");
		}

		# Create the record
		$schema->resultset('Author')->create( {
			id    => $id,
			name  => $found[0]->name,
			email => $found[0]->address,
			} );
		$created++;
	}

	$created;
}

=pod

=head2 load_packages

  CPAN::Index::Loader->load_packages( $schema, $handle );

The C<load_packages> method populates the C<package> table from the CPAN
F<02packages.details.txt.gz> file.

The C<package> table in the SQLite database should already be empty
B<before> this method is called.

Returns the number of packages added to the database, or throws an
exception on error.

=cut

sub load_packages {
	my $self   = shift;
	my $schema = _INSTANCE(shift, 'DBIx::Class::Schema')
		or Carp::croak("Did not provide a DBIx::Class::Schema param");
	my $handle = _INSTANCE(shift, 'IO::Handle')
		or Carp::croak("Did not provide an IO::Handle param");

	# Advance past the header, to the first blank line
	while ( my $line = $handle->getline ) {
		last if $line !~ /[^\s\012\015]/;
	}

	# Process the author records
	my $created = 0;
	while ( my $line = $handle->getline ) {
		unless ( $line =~ /^(\S+)\s+(\S+)\s+(.+?)[\012\015]+$/ ) {
			Carp::croak("Invalid 02packages.details.txt.gz line '$line'");
		}
		my $name    = $1;
		my $version = $2 eq 'undef' ? undef : $2;
		my $path    = $3;

		# Create the record
		$schema->resultset('Package')->create( {
			name    => $name,
			version => $version,
			path    => $path,
			} );
		$created++;
	}

	$created;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Index>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

Parts based on various modules by Leon Brocard E<lt>acme@cpan.orgE<gt>

=head1 SEE ALSO

Related: L<CPAN::Index>, L<CPAN>

Based on: L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
