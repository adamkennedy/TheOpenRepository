package Parse::Marpa::Offset;

use 5.010;
use strict;
use warnings;
use integer;

sub import {
    my $class = shift;
    my $struct_name = shift;
    my $pkg = caller;
    # say STDERR $pkg;
    my $prefix = $pkg . '::' . $struct_name . '::';
    my $offset = 0;

    no strict "refs";
    for my $field (@_) {
       # offset must be copy, because contents of sub must be constant
       my $field_name = $prefix . $field;
       # say STDERR $field_name, ' => ', $offset;
       *$field_name = sub () { $offset };
       $offset++;
    }
}

1;
