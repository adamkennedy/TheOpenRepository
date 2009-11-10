package Marpa::UrHTML::Internal::Tie;

use 5.010;
use warnings;
use strict;
use integer;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use English qw( -no_match_vars );

use Marpa::Internal;

## no critic (Miscellanea::ProhibitTies)

package Marpa::Internal::Tie::Id;

sub TIESCALAR {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub FETCH {
    return undef;
} ## end sub FETCH

sub STORE {
    Marpa::exception('ID is not writeable');
}

tie $Marpa::UrHTML::ID, __PACKAGE__;

package Marpa::Internal::Tie::Class;

sub TIESCALAR {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub FETCH {
    return undef;
} ## end sub FETCH

sub STORE {
    Marpa::exception('CLASS is not writeable');
}

tie $Marpa::UrHTML::CLASS, __PACKAGE__;

1;
