package Pod::Abstract::Serial;
use strict;

my $serial_number = 0;

sub next {
    return ++$serial_number;
}

sub last {
    return $serial_number;
}

sub set {
    $serial_number = shift;
}

1;
