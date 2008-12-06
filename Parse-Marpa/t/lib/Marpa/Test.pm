package Marpa::Test;
use 5.010;
use strict;
use warnings;
use Carp;

croak("Test::More not loaded")
    unless defined &Test::More::is;

BEGIN { eval "use Test::Differences"; }
use Data::Dumper;

sub is {
    goto &eq_or_diff if defined &eq_or_diff && @_ > 1;
    @_ = map { ref $_ ? Dumper( @_ ) : $_ } @_;
    goto &Test::More::is;
}

