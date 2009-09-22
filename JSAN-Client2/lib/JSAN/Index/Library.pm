package JSAN::Index::Library;

use strict;
use warnings;
use Carp                     ();
use JSAN::Index::Extractable ();

our $VERSION = '0.20';
our @ISA     = 'JSAN::Index::Extractable';

sub fetch_distribution {
    JSAN::Index::Distribution->retrieve(
        name => $_[0]->distribution,
    );
}

sub fetch_release {
    JSAN::Index::Release->retrieve(
        id => $_[0]->release,
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

sub extract_resource {
	shift->fetch_release->extract_resource(@_);
}

1;

__END__

=pod

=head1 NAME

JSAN::Index::Library - JSAN::Index class for the library table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = JSAN::Index::Library->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = JSAN::Index::Library->select(
      'where name > ? order by name',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
library table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM library> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<JSAN::Index::Library> objects when called in list context, or a
reference to an C<ARRAY> of B<JSAN::Index::Library> objects when called in scalar
 context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = JSAN::Index::Library->count;
  
  # How many objects 
  my $small = JSAN::Index::Library->count(
      'where name > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
library table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM library> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head1 ACCESSORS

=head2 name

  if ( $object->name ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The library table was originally created with the
following SQL command.

  CREATE TABLE library (
      name varchar (
          100
      )
      NOT NULL,
      distribution varchar (
          100
      )
      NOT NULL,
      release int (
          11
      )
      NOT NULL,
      version varchar (
          100
      )
  ,
      doc varchar (
          100
      )
      NOT NULL,
      PRIMARY KEY (
          name
      )
  )


=head1 SUPPORT

JSAN::Index::Library is part of the L<JSAN::Index> API.

See the documentation for L<JSAN::Index> for more information.

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
