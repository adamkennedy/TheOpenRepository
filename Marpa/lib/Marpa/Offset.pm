package Marpa::Offset;

use 5.010;
use strict;
use warnings;
use integer;

sub import {
    my ( $class, @fields ) = @_;
    my $pkg = caller;
    if ( $fields[0] =~ /\A [:] package [=] /xms ) {
        $pkg = shift @fields;
        $pkg =~ s/ \A [:] package [=] //xms;
    }
    my $prefix = $pkg . q{::};
    my $offset = -1;

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    ## use critic
    for my $field (@fields) {

        if ( $field !~ s/\A=//xms ) {
            $offset++;
        }

        if ( $field =~ / \A ( [^=]* ) = ( [0-9+-]* ) \z/xms ) {
            $field  = $1;
            $offset = $2 + 0;
        }

        Marpa::exception("Unacceptable field name: $field")
            if $field =~ /[^A-Z0-9_]/xms;
        my $field_name = $prefix . $field;
        *{$field_name} = sub () {$offset};
    } ## end for my $field (@fields)
    return 1;
} ## end sub import

1;
