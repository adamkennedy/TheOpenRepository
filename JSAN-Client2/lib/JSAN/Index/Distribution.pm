package JSAN::Index::Distribution;

use strict;
use warnings;
use JSAN::Index::Extractable ();
use JSAN::Index::Release     ();

our $VERSION = '0.20';
our @ISA     = 'JSAN::Index::Extractable';

sub releases {
    JSAN::Index::Release->select('where distribution = ?', $_[0]->name);
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

sub latest_release {
    my $self     = shift;
    my @releases = $self->releases;
    unless ( @releases ) {
        Carp::croak( "No releases found for distribution " . $self->name );
    }
    @releases = sort { $b->version <=> $a->version } @releases;
    $releases[0];
}

1;

__END__

=pod

=head1 NAME

JSAN::Index::Distribution - JSAN::Index class for the distribution table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = JSAN::Index::Distribution->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = JSAN::Index::Distribution->select(
      'where name > ? order by name',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
distribution table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM distribution> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<JSAN::Index::Distribution> objects when called in list context, or a
reference to an C<ARRAY> of B<JSAN::Index::Distribution> objects when called in scalar
 context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = JSAN::Index::Distribution->count;
  
  # How many objects 
  my $small = JSAN::Index::Distribution->count(
      'where name > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
distribution table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM distribution> section of the query, followed by variables
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

The distribution table was originally created with the
following SQL command.

  CREATE TABLE distribution (
      name varchar (
          100
      )
      NOT NULL,
      doc varchar (
          100
      )
      NOT NULL,
      PRIMARY KEY (
          name
      )
  )


=head1 SUPPORT

JSAN::Index::Distribution is part of the L<JSAN::Index> API.

See the documentation for L<JSAN::Index> for more information.

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
