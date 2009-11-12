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

sub tiescalar_stub {
    my ($class) = @_;
    my $instance;    # not used for anything
    return bless \$instance => $class;
}

sub create_not_writeable {
    my ($var_name) = @_;
    return sub { Marpa::exception($var_name . ' is not writeable') }
}

sub tie_attribute {
    my ($attribute_name) = @_;
    my $package_name     = 'Marpa::Internal::Tie::' . ucfirst $attribute_name;
    my $tied_var_name    = 'Marpa::UrHTML::Attribute::' . uc $attribute_name;

    no strict 'refs';
    *{ $package_name . '::TIESCALAR' } =
        *{'Marpa::UrHTML::Internal::Tie::tiescalar_stub'}{'CODE'};
    *{ $package_name . '::FETCH' } =
        Marpa::UrHTML::Internal::Tie::create_fetch_attribute_closure(lc $attribute_name);
    *{ $package_name . '::STORE' } =
        Marpa::UrHTML::Internal::Tie::create_not_writeable(
        uc $attribute_name );
    use strict;

    my $var;
    tie $var, $package_name;

    no strict 'refs';
    *{$tied_var_name} = \$var;
    use strict;

    return 1;
} ## end sub tie_attribute

tie_attribute('id');
tie_attribute('class');
tie_attribute('title');

# Allow Short form of the attribute names,
# when there are no conflicts
no strict 'refs';
*{'Marpa::UrHTML::ID'} = *{'Marpa::UrHTML::Attribute::ID'}{'SCALAR'};
*{'Marpa::UrHTML::CLASS'} = *{'Marpa::UrHTML::Attribute::CLASS'}{'SCALAR'};
*{'Marpa::UrHTML::TITLE'} = *{'Marpa::UrHTML::Attribute::TITLE'}{'SCALAR'};
use strict;

1;
