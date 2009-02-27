package Pod::Abstract::Filter::cut;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my @cut = $pa->select("//#cut");
    foreach my $cut (@cut) {
        $cut->detach;
    }
    
    return $pa;
}

1;
