package Marpa::UrHTML::Internal::Callback;

use 5.010;
use warnings;
use strict;
use integer;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use English qw( -no_match_vars );

use Marpa::Internal;

sub create_fetch_attribute_closure {
    my ($attribute) = @_;
    return sub {
        return if not $Marpa::UrHTML::Internal::TDESC_LIST;
        return
            if not my $first_tdesc =
                $Marpa::UrHTML::Internal::TDESC_LIST->[0];
        return if not my $type = $first_tdesc->[0];
        return if $type ne 'TOKEN_SPAN';
        my $first_token_number = $first_tdesc->[1];
        my $parse_instance     = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
        Marpa::exception(
            qq{Attempt to fetch attribute "$attribute" from undefined parse instance}
        ) if not defined $parse_instance;
        my $tokens           = $parse_instance->{tokens};
        my $first_token      = $tokens->[$first_token_number];
        my $first_token_type = $first_token->[0];
        return if $first_token_type ne 'S';
        my $attribute_value = $first_token->[4]->{$attribute};
        return defined $attribute_value ? lc $attribute_value : undef;
        }
} ## end sub create_fetch_attribute_closure

no strict 'refs';
*{'Marpa::UrHTML::id'}    = create_fetch_attribute_closure('id');
*{'Marpa::UrHTML::class'} = create_fetch_attribute_closure('class');
*{'Marpa::UrHTML::title'} = create_fetch_attribute_closure('title');
use strict;

package Marpa::UrHTML::Internal::Callback;

sub set_up_elements {
    my $elements = $Marpa::UrHTML::Internal::NODE_SCRATCHPAD->{elements} = [];

    # Assume the parent checked to see if this exists
    my $tdesc_list = $Marpa::UrHTML::Internal::TDESC_LIST;
    TDESC:
    for my $tdesc_ix ( 0 .. $#{$Marpa::UrHTML::Internal::TDESC_LIST} ) {
        next TDESC if $tdesc_list->[$tdesc_ix]->[0] ne 'ELE';
        push @{$elements}, $tdesc_ix;
    }
    return $elements;
} ## end sub set_up_elements

sub Marpa::UrHTML::element_values {
    my $tdesc_list = $Marpa::UrHTML::Internal::TDESC_LIST;
    Marpa::exception('Attempt to get element values of non-existent node')
        if not defined $tdesc_list;
    my $elements = $Marpa::UrHTML::Internal::NODE_SCRATCHPAD->{elements}
        // Marpa::UrHTML::Internal::Tie::set_up_elements();
    return [ map { $_->[3] } @{$tdesc_list}[ @{$elements} ] ];
} ## end sub FETCH

sub Marpa::UrHTML::literal {
    say STDERR "Fetch of ", __PACKAGE__;
    return q{} if $Marpa::Internal::SETTING_NULL_VALUES;
    my $tdesc_list = $Marpa::UrHTML::Internal::TDESC_LIST;
    say STDERR "tdesc_list: ", Data::Dumper::Dumper($tdesc_list);
    Marpa::exception('Attempt to get element values of non-existent node')
        if not defined $tdesc_list;
    my $parse_instance = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    Marpa::exception(
        'Attempt to read element values in undefined parse instance')
        if not defined $parse_instance;
    return Marpa::UrHTML::Internal::tdesc_list_to_text( $parse_instance,
        $tdesc_list );
} ## end sub FETCH

1;
