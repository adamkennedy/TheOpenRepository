package SQL::Script;

=pod

=head1 NAME

SQL::Script - An object representing a series of SQL statements, normally
stored in a file

=head1 PREAMBLE

For far too long we have been throwing SQL scripts at standalone binary
clients, it's about time we had some way to throw them at the DBI instead.

Since I'm sick and tired of waiting for someone that knows more about SQL
than me to do it properly, I shall implement it myself, and wait for said
people to send me patches to fix anything I do wrong.

At least this way I know the API will be done in a usable way.

=head1 DESCRIPTION

This module provides a very simple and straight forward way to work with a
file or string that contains a series of SQL statements.

In essense, all this module really does is slurp in a file and split it
by semi-colon+newline.

However, by providing an initial data object and API for this function, my
hope is that as more people use this module, better mechanisms can be
implemented underneath the same API at a later date to read and split the
script in a more thorough and complete way.

It may well become the case that SQL::Script acts as a front end for a whole
quite of format-specific SQL splitters.

=head1 METHODS

=cut

use strict;

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
    my $class = shift;

    # Create the object
    my $self = bless {
        split_by => ';\n',
        }, $class;

    return $self;
}

sub statements {

}

sub _SLURP {
    return undef unless defined $_[0];
    if ( _SCALARLIKE(
}

1;

=pod

=head1 SUPPORT

=cut
