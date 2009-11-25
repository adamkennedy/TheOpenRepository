package Marpa::UrHTML::Internal::Callback;

use 5.010;
use warnings;
use strict;
use integer;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use English qw( -no_match_vars );

use Marpa::Internal;

sub Marpa::UrHTML::element_parts {

    my $element = $Marpa::UrHTML::Internal::NODE_SCRATCHPAD->{element};
    Marpa::exception('The element_parts callback was called on a non-element')
        if not $element;

    my $parse_instance = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    Marpa::exception(
        qq{Attempt to fetch element parts from an undefined parse instance}
    ) if not defined $parse_instance;

    # This routine assumes that it is being called on a newly
    # assembled element.  That means the start and end tags are
    # have their own tdesc's at the beginning and end of the
    # tdesc_list, and that they are either TOKEN_SPAN's with
    # a single token (explicit tags),
    # or EMPTY tdesc's (implicit tags).

    my $start_tdesc = $Marpa::UrHTML::Internal::TDESC_LIST->[0];
    my $start_tag;
    if ( $start_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] ne 'EMPTY' ) {
        my $start_tag_token =
            $start_tdesc->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];

        # Inlining this might be faster, especially since I have to dummy
        # up a tdesc list to make it work.
        $start_tag =
            Marpa::UrHTML::Internal::tdesc_list_to_literal( $parse_instance,
            [ [ TOKEN_SPAN => $start_tag_token, $start_tag_token ] ] );
    } ## end if ( $start_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE...])

    return $start_tag if not wantarray;

    my $end_tdesc = $Marpa::UrHTML::Internal::TDESC_LIST->[-1];
    my $end_tag;
    if ( $end_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] ne 'EMPTY' ) {
        my $end_tag_token =
            $end_tdesc->[Marpa::UrHTML::Internal::TDesc::END_TOKEN];

        # Inlining this might be faster, especially since I have to dummy
        # up a tdesc list to make it work.
        $end_tag =
            Marpa::UrHTML::Internal::tdesc_list_to_literal( $parse_instance,
            [ [ TOKEN_SPAN => $end_tag_token, $end_tag_token ] ] );
    } ## end if ( $end_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE...])

    # say STDERR "length of TDESC_LIST: ", scalar @{$Marpa::UrHTML::Internal::TDESC_LIST};

    # While non-existent tags are returned as undef,
    # content is regarded as always present and
    # therefore is returned as a zero-length string
    my $contents_tdesc_list =
        [ @{$Marpa::UrHTML::Internal::TDESC_LIST}
            [ 1 .. $#{$Marpa::UrHTML::Internal::TDESC_LIST} - 1 ] ];

    # say STDERR "start_tdesc=", Data::Dumper::Dumper($start_tdesc);
    # say STDERR "end_tdesc=",   Data::Dumper::Dumper($end_tdesc);
    # say STDERR "contents_tdesc_list=",
    #    Data::Dumper::Dumper($contents_tdesc_list);

    my $contents =
        scalar @{$contents_tdesc_list}
        ? Marpa::UrHTML::Internal::tdesc_list_to_literal( $parse_instance,
        $contents_tdesc_list )
        : \q{};

    return ($start_tag, $contents, $end_tag);

} ## end sub Marpa::UrHTML::element_parts

no strict 'refs';
*{'Marpa::UrHTML::start_tag'}    = \&Marpa::UrHTML::parts;
use strict;

# This assumes that a start token, if there is one
# with attributes, is the first token
sub create_fetch_attribute_closure {
    my ($attribute) = @_;
    return sub {
        return if not $Marpa::UrHTML::Internal::TDESC_LIST;
        return
            if not my $first_tdesc =
                $Marpa::UrHTML::Internal::TDESC_LIST->[0];
        return
            if not my $type =
                $first_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE];
        return if $type ne 'TOKEN_SPAN';
        my $first_token_number =
            $first_tdesc->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];
        my $parse_instance = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
        Marpa::exception(
            qq{Attempt to fetch attribute "$attribute" from undefined parse instance}
        ) if not defined $parse_instance;
        my $tokens      = $parse_instance->{tokens};
        my $first_token = $tokens->[$first_token_number];
        my $first_token_type =
            $first_token->[Marpa::UrHTML::Internal::Token::TYPE];
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
        next TDESC
            if $tdesc_list->[$tdesc_ix]
                ->[Marpa::UrHTML::Internal::TDesc::TYPE] ne 'ELE';
        push @{$elements}, $tdesc_ix;
    } ## end for my $tdesc_ix ( 0 .. $#{$Marpa::UrHTML::Internal::TDESC_LIST...})
    return $elements;
} ## end sub set_up_elements

sub Marpa::UrHTML::tagname {
    # say STDERR join " ", __FILE__, __LINE__, "in tagname()";
    return $Marpa::UrHTML::Internal::NODE_SCRATCHPAD->{element};
}

sub Marpa::UrHTML::element_values {
    my $tdesc_list = $Marpa::UrHTML::Internal::TDESC_LIST;
    Marpa::exception('Attempt to get element values of non-existent node')
        if not defined $tdesc_list;
    my $elements = $Marpa::UrHTML::Internal::NODE_SCRATCHPAD->{elements}
        // Marpa::UrHTML::Internal::Callback::set_up_elements();
    return [ map { $_->[3] } @{$tdesc_list}[ @{$elements} ] ];
} ## end sub Marpa::UrHTML::element_values

sub Marpa::UrHTML::literal {
    return q{} if $Marpa::Internal::SETTING_NULL_VALUES;
    my $tdesc_list = $Marpa::UrHTML::Internal::TDESC_LIST;
    Marpa::exception('Attempt to get element values of non-existent node')
        if not defined $tdesc_list;
    my $parse_instance = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    Marpa::exception(
        'Attempt to read element values in undefined parse instance')
        if not defined $parse_instance;
    return Marpa::UrHTML::Internal::tdesc_list_to_literal( $parse_instance,
        $tdesc_list );
} ## end sub Marpa::UrHTML::literal

sub Marpa::UrHTML::offset {
    my $tdesc_list     = $Marpa::UrHTML::Internal::TDESC_LIST;
    my $parse_instance = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    Marpa::exception('Attempt to read offset from undefined parse instance')
        if not defined $parse_instance;

    # Start offset is start token of first tdesc
    my $token_offset;
    #<<< As of 2009-11-22 perltidy cycles on this
    TDESC: for my $tdesc ( @{$tdesc_list} ) {
        last TDESC
            if defined( $token_offset =
                $tdesc->[Marpa::UrHTML::Internal::TDesc::START_TOKEN] );
    }
    #>>>
    return Marpa::UrHTML::Internal::earleme_to_offset( $parse_instance,
        $token_offset );
} ## end sub Marpa::UrHTML::offset

1;
