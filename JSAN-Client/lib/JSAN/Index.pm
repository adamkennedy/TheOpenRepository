package JSAN::Index;

=pod

=head1 NAME

JSAN::Index - JavaScript Archive Network (JSAN) SQLite/ORLite Index

=head1 DESCRIPTION

JSAN is the JavaScript Archive Network, a port of CPAN to JavaScript.

You can find the JSAN at L<http://openjsan.org>.

As well as a flat text file index like CPAN, the JSAN index is also
distributed as a L<DBD::SQLite> database.

C<JSAN::Index> is a L<ORLite> wrapper built around the JSAN
SQLite index.

It allow you to easily do all sorts of nifty things with the index in a
simple and straight forward way.

=head2 Using The JSAN Index / Terminology

Once loaded, most of the functionality of the index is accessed through
the classes that implement the various objects in the index.

These are:

=over 4

=item L<JSAN::Index::Author>

An author is a single human (or under certain very special circumstances
a company or mailing list) that creates distributions and uploads them
to the JSAN.

=item L<JSAN::Index::Distribution>

A distribution is a single software component that may go through a number
of releases

=item L<JSAN::Index::Release>

A release is a compressed archive file containing a single version of a
paricular distribution.

=item L<JSAN::Index::Library>

A library is a single class, or rather a "pseudo-namespace", that
defines an interface to provide some functionality. Distributions often
contain a number of libraries, making up a complete "API".

=back

=head1 METHODS

There are only a very limited number of utility methods available
directly from the C<JSAN::Index> class itself.

=cut

use 5.008005;
use strict;
use warnings;
use Params::Util   1.00 ();
use ORLite::Mirror 1.17 ();

our $VERSION = '0.21';

sub import {
    my $class  = shift;
    my $params = Params::Util::_HASH(shift) || {};

    # Pass through any params from above
    $params->{url}    ||= 'http://openjsan.org/index.sqlite';
    $params->{maxage} ||= 24 * 60 * 60; # One day

    # Don't generate the table classes because we have inlined the
    # generated code ourself for speed and to make it work a bit more
    # like Class::DBI
    $params->{tables} ||= 0;

    # Prevent double-initialisation
    $class->can('orlite') or
    ORLite::Mirror->import( $params );

    return 1;
}

use JSAN::Index::Author       ();
use JSAN::Index::Library      ();
use JSAN::Index::Release      ();
use JSAN::Index::Distribution ();





#####################################################################
# Top-level Methods

=pod

=head2 dependency param => $value

The C<dependency> method creates and returns an dependency resolution 
object that is used by L<JSAN::Client> to schedule which releases to
install.

If the optional parameter 'build' is true, creates a build-time
dependency resolve, which will additionally install releases only needed
for testing.

Returns an L<Algorithm::Dependency> object.

=cut

sub dependency {
    my $class  = shift;
    JSAN::Index::Release::_Dependency->new( @_ );
}





#####################################################################
# Private Classes

# Algorithm::Dependency::Ordered for the ::Release data

package JSAN::Index::Release::_Dependency;

use Params::Util '_INSTANCE';

use base 'Algorithm::Dependency::Ordered';

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my %params = @_;

    # Apply defaults
    $params{source} ||= JSAN::Index::Release::_Source->new( %params );

    # Hand off to superclass constructor
    my $self = $class->SUPER::new( %params )
        or Carp::croak("Failed to create JSAN::Index::Release::_Dependency object");

    # Save the type for later
    $self->{build} = !! $params{build};

    $self;
}

sub build { $_[0]->{build} }

sub schedule {
    my $self     = shift;
    my @schedule = @_;

    # Convert things in the schedule from index objects to
    # release source strings as needed
    my @cleaned = ();
    foreach my $item ( @schedule ) {
        if ( defined $item and ! ref $item and $item =~ /^(?:\w+)(?:\.\w+)*$/ ) {
            $item = JSAN::Index::Library->retrieve( name => $item );
        }
        if ( _INSTANCE($item, 'JSAN::Index::Library') ) {
            $item = $item->release;
        }
        if ( _INSTANCE($item, 'JSAN::Index::Release') ) {
            $item = $item->source;
        }
        push @cleaned, $item;
    }

    $self->SUPER::schedule(@cleaned);
}

# Algorithm::Dependency::Source for the ::Release data

package JSAN::Index::Release::_Source;

use Algorithm::Dependency::Item ();
use base 'Algorithm::Dependency::Source';

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my %params = @_;

    # Create the basic object
    my $self = $class->SUPER::new();

    # Set the methods to use
    $self->{requires_releases} = 1;
    if ( $params{build} ) {
        $self->{build_requires_releases} = 1;
    }

    $self;
}

sub _load_item_list {
    my $self = shift;

    ### FIXME: This is crudely effective, but a little innefficient.
    ###        Later, we should be able to determine which subset of
    ###        these can never be called, and leave them out of the list.

    # Get every single release in the index
    my @releases = JSAN::Index::Release->retrieve_all;

    # Wrap the releases in the Adapter objects
    my @items  = ();
    foreach my $release ( @releases ) {
        my $id      = $release->source;

        # Get the list of dependencies
        my @depends = ();
        if ( $self->{requires_releases} ) {
            push @depends, $release->requires_releases;
        }
        if ( $self->{build_requires_releases} ) {
            push @depends, $release->build_requires_releases;
        }

        # Convert to a distinct source list
        my %seen = ();
        @depends = grep { ! $seen{$_} } map { $_->source } @depends;

        # Add the dependency
        my $item = Algorithm::Dependency::Item->new( $id => @depends )
            or die "Failed to create Algorithm::Dependency::Item";
        push @items, $item;
    }

    \@items;
}

1;

__END__

=pod

=head2 dsn

  my $string = JSAN::Index->dsn;

The C<dsn> accessor returns the L<DBI> connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = JSAN::Index->dbh;

To reliably prevent potential L<SQLite> deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with connection management in
L<ORLite>.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond your immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = JSAN::Index->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 SUPPORT

JSAN::Index is based on L<ORLite> 1.25.

Documentation created by L<ORLite::Pod> 0.07.

For general support please see the support section of the main
project documentation.

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
