package Marpa::Internal::Tie;

use 5.010;
use warnings;
use strict;
use integer;

use Smart::Comments '-ENV';

### Using smart comments <where>...

use English qw( -no_match_vars );

use Marpa::Internal;
use Marpa::Evaluator;

## no critic (Miscellanea::ProhibitTies)

package Marpa::Internal::Tie::Location;

sub TIESCALAR {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub FETCH {
    Marpa::exception('No context for location tie')
        if not my $context = $Marpa::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    Marpa::exception('LOCATION called outside and-node context')
        if not $context_type ~~ [ 'setup and-node', 'rank and-node' ];
    return $and_node->[Marpa::Internal::And_Node::START_EARLEME];
} ## end sub FETCH

sub STORE {
    Marpa::exception('Location tie is not writeable');
}

tie $Marpa::LOCATION, __PACKAGE__;

package Marpa::Internal::Tie::Token_Location;

sub TIESCALAR {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub FETCH {
    Marpa::exception('No context for TOKEN_LOCATION tie')
        if not my $context = $Marpa::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    Marpa::exception('TOKEN_LOCATION called outside and-node context')
        if not $context_type ~~ [ 'setup and-node', 'rank and-node' ];
    my $predecessor_id =
        $and_node->[Marpa::Internal::And_Node::PREDECESSOR_ID];

    return $and_node->[Marpa::Internal::And_Node::START_EARLEME]
        if not defined $predecessor_id;
    my $eval_instance = $Marpa::Internal::EVAL_INSTANCE;
    my $or_nodes = $eval_instance->[Marpa::Internal::Evaluator::OR_NODES];

    return $or_nodes->[$predecessor_id]
        ->[Marpa::Internal::Or_Node::END_EARLEME];
} ## end sub FETCH

sub STORE {
    Marpa::exception('TOKEN_LOCATION tie is not writeable');
}

tie $Marpa::TOKEN_LOCATION, __PACKAGE__;

package Marpa::Internal::Tie::LENGTH;

sub TIESCALAR {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub FETCH {
    Marpa::exception('No context for LENGTH tie')
        if not my $context = $Marpa::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    Marpa::exception('LENGTH called outside and-node context')
        if not $context_type ~~ [ 'setup and-node', 'rank and-node' ];
    return $and_node->[Marpa::Internal::And_Node::END_EARLEME]
        - $and_node->[Marpa::Internal::And_Node::START_EARLEME];
} ## end sub FETCH

sub STORE {
    Marpa::exception('TOKEN_LOCATION tie is not writeable');
}

tie $Marpa::LENGTH, __PACKAGE__;

1;
