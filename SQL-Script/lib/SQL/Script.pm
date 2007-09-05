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
use Carp         'croak';
use Params::Util '_STRING', '_SCALAR';

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
        split_by   => ';\n',
        statements => [],
        }, $class;

    # Normalise params
    if ( _STRING($self->split_by) ) {
        my $escaped = quotemeta $self->split_by;
        
    }

    return $self;
}

sub read {
    my $self  = shift;
    my $input = _READSCALAR(shift) or return undef;
    
}

sub split_by {
    $_[0]->{split_by};
}

sub statements {
    if ( wantarray ) {
        return @{$self->{statements}};
    } else {
        return scalar @{$self->{statements}};
    }
}





#####################################################################
# Main Methods

sub split_sql {
    my $self   = shift;
    my $sql    = _SCALAR(shift) or return undef;

    # Find the regex to split by
    my $regexp;
    if ( _STRING($self->split_by) ) {
        $regexp = quotemeta $self->split_by;
        $regexp = qr/$regexp/;
    } elsif ( ref($self->split_by) eq 'Regexp' ) {
        $regexp = $self->split_by;
    } else {
        croak("Unknown or unsupported split_by value");
    }

    # Split the sql
    my @statements = split( $regexp, $sql );
    $self->{statements} = \@statements;
    return 1;
}





#####################################################################
# Support Functions

sub _INPUT_SCALAR {
    unless ( defined $_[0] ) {
        return undef;
    }
    unless ( ref $_[0] ) {
        unless ( -f $_[0] and -r _ ) {
            return undef;
        }
        local $/ = undef;
        open( FILE, $_[0] ) or return undef;
        my $buffer = <FILE> or return undef;
        close FILE          or return undef;
        return \$buffer;
    }
    if ( _SCALAR($_[0]) ) {
        return shift;
    }
    if ( _HANDLE($_[0]) ) {
        local $/ = undef;
        my $buffer = <$_[0]>;
        return \$buffer;
    }
    return undef;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Script>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
