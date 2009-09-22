package JSAN::Index::Author;

use strict;
use warnings;

our $VERSION = '0.20';

sub releases {
    JSAN::Index::Release->select( 'where author = ?', $_[0]->login );
}

sub retrieve {
    my $self   = shift;
    my %params = @_;
    my $sql    = join " and ", map { "$_ = ?" } keys(%params); 
    my $result = __PACKAGE__->select("where $sql", values(%params));
    
    if (scalar(@$result) == 1) {
        return $result->[0]
    } 
    
    return $result
}

1;

__PACKAGE__;

=pod

=head1 NAME

JSAN::Index::Author - JSAN::Index class for the author table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = JSAN::Index::Author->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = JSAN::Index::Author->select(
      'where login > ? order by login',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
author table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM author> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<JSAN::Index::Author> objects when called in list context, or a
reference to an C<ARRAY> of B<JSAN::Index::Author> objects when called in scalar
 context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = JSAN::Index::Author->count;
  
  # How many objects 
  my $small = JSAN::Index::Author->count(
      'where login > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
author table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM author> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head1 ACCESSORS

=head2 login

  if ( $object->login ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The author table was originally created with the
following SQL command.

  CREATE TABLE author (
      login varchar (
          100
      )
      NOT NULL,
      name varchar (
          100
      )
      NOT NULL,
      doc varchar (
          100
      )
      NOT NULL,
      email varchar (
          100
      )
      NOT NULL,
      url varchar (
          100
      )
  ,
      PRIMARY KEY (
          login
      )
  )


=head1 SUPPORT

JSAN::Index::Author is part of the L<JSAN::Index> API.

See the documentation for L<JSAN::Index> for more information.

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

