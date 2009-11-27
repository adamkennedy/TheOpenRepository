package Marpa::UrHTML;

use 5.010;
use strict;
use warnings;

use Carp ();
use English qw( -no_match_vars );

use HTML::PullParser;
use HTML::Entities qw(decode_entities);
use HTML::Tagset ();
use Marpa;
use Marpa::Internal;

# use Smart::Comments '-ENV';

### <where> Using smart comments ...

package Marpa::UrHTML::Internal;

use Marpa::Internal;

BEGIN {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval 'use Devel::Size';
    ## use critic
} ## end BEGIN

sub total_size {
    Marpa::exception('Devel::Size not loaded')
        if not defined &Devel::Size::total_size;
    goto &Devel::Size::total_size;
}

use Marpa::Offset qw(
    :package=Marpa::UrHTML::Internal::TDesc
    TYPE
    START_TOKEN
    END_TOKEN
);

use Marpa::Offset qw(
    :package=Marpa::UrHTML::Internal::TDesc::Element
    TYPE
    START_TOKEN
    END_TOKEN
    VALUE
    NODE_DATA
);

use Marpa::Offset qw(
    :package=Marpa::UrHTML::Internal::Token
    TYPE
    START_OFFSET
    END_OFFSET
);

use Marpa::UrHTML::Callback;

sub per_element_handlers {
    my ( $element, $user_handlers ) = @_;
    return {} if not $element;
    return {} if not $user_handlers;
    my $wildcard_handlers    = $user_handlers->{ANY} // {};
    my %handlers             = %{$wildcard_handlers};
    my $per_element_handlers = $user_handlers->{$element} // {};
    @handlers{ keys %{$per_element_handlers} } =
        values %{$per_element_handlers};
    return \%handlers;
} ## end sub per_element_handlers

sub tdesc_list_to_literal {
    my ( $self, $tdesc_list ) = @_;
    
    # say STDERR "in tdesc_list_to_literal, tdesc_list=", Data::Dumper::Dumper($tdesc_list);

    my $text     = q{};
    my $document = $self->{document};
    my $tokens   = $self->{tokens};
    TDESC: for my $tdesc ( @{$tdesc_list} ) {
        given ( $tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] ) {
            when ('POINT') { break; }
            when ('VALUED_SPAN') {
                if (defined(
                        my $value =
                            $tdesc
                            ->[Marpa::UrHTML::Internal::TDesc::Element::VALUE]
                    )
                    )
                {
                    $text .= $value;
                    break;    # next TDESC;
                } ## end if ( defined( my $value = $tdesc->[...]))

                # next TDESC if no first token id
                #<<< As of 2009-11-22 perltidy cycles on this code
                break
                    if not defined( my $first_token_id = $tdesc
                        ->[ Marpa::UrHTML::Internal::TDesc::START_TOKEN ] );
                #>>>

                # next TDESC if no last token id
                #<<< As of 2009-11-22 perltidy cycles on this code
                break
                    if not defined( my $last_token_id =
                        $tdesc->[Marpa::UrHTML::Internal::TDesc::END_TOKEN] );
                #>>>

                my $offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::UrHTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::UrHTML::Internal::Token::END_OFFSET];
                $text .= substr ${$document}, $offset,
                    ( $end_offset - $offset );
            } ## end when ('VALUED_SPAN')
            when ('UNVALUED_SPAN') {
                my $first_token_id =
                    $tdesc->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];
                my $last_token_id =
                    $tdesc->[Marpa::UrHTML::Internal::TDesc::END_TOKEN];
                my $offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::UrHTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::UrHTML::Internal::Token::END_OFFSET];

                $text .= substr ${$document}, $offset,
                    ( $end_offset - $offset );
            } ## end when ('UNVALUED_SPAN')
            default {
                Marpa::exception(qq{Internal error: unknown tdesc type "$_"});
            }
        } ## end given
    } ## end for my $tdesc ( @{$tdesc_list} )
    return \$text;
} ## end sub tdesc_list_to_literal

# Convert a list of text descriptions to text
sub default_top_handler {
    my ( $dummy, @tdesc_lists ) = @_;

    my $self = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
    return tdesc_list_to_literal( $self, \@tdesc_list );

} ## end sub default_top_handler

# Convert a list of text descriptions to a
# single, shortened text description
sub create_tdesc_handler {
    my ( $self, $element ) = @_;
    my $handlers_by_class =
        per_element_handlers( $element,
        ( $self ? $self->{user_handlers_by_class} : {} ) );
    my $handlers_by_id =
        per_element_handlers( $element,
        ( $self ? $self->{user_handlers_by_id} : {} ) );

    return sub {
        my ( $dummy, @tdesc_lists ) = @_;

        my @tdesc_list =  map { @{$_} } grep {defined} @tdesc_lists;
        local $Marpa::UrHTML::Internal::TDESC_LIST = \@tdesc_list;

        my @token_ids = sort { $a <=> $b } grep {defined} map {
            @{$_}[
                Marpa::UrHTML::Internal::TDesc::START_TOKEN,
                Marpa::UrHTML::Internal::TDesc::END_TOKEN
                ]
        } @tdesc_list;
        my $first_token_id = $token_ids[0];
        my $last_token_id  = $token_ids[-1];
        my $per_node_data  = {
            element        => $element,
            first_token_id => $first_token_id,
            last_token_id  => $last_token_id,
        };
        if ( $tdesc_list[0]->[Marpa::UrHTML::Internal::TDesc::TYPE] ne
            'POINT' )
        {
            $per_node_data->{start_tag_token_id} = $first_token_id;
        }
        if ( $tdesc_list[-1]->[Marpa::UrHTML::Internal::TDesc::TYPE] ne
            'POINT' )
        {
            $per_node_data->{end_tag_token_id} = $last_token_id;
        }
        local $Marpa::UrHTML::Internal::PER_NODE_DATA = $per_node_data;

        my $self           = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
        my $trace_fh       = $self->{trace_fh};
        my $trace_handlers = $self->{trace_handlers};

        my $tokens = $self->{tokens};

        my $user_handler;
        GET_USER_HANDLER: {
            if ( my $id = Marpa::UrHTML::id() ) {
                if ( $user_handler = $handlers_by_id->{$id} ) {
                    if ($trace_handlers) {
                        say {$trace_fh}
                            "Resolved to user handler by element ($element) and id ($id)";
                    }
                    last GET_USER_HANDLER;
                } ## end if ( $user_handler = $handlers_by_id->{$id} )
            } ## end if ( my $id = Marpa::UrHTML::id() )
            if ( my $class = Marpa::UrHTML::class() ) {
                if ( $user_handler = $handlers_by_class->{$class} ) {
                    if ($trace_handlers) {
                        say {$trace_fh}
                            "Resolved to user handler by element ($element) and class ($class)";
                    }
                    last GET_USER_HANDLER;
                } ## end if ( $user_handler = $handlers_by_class->{$class} )
            } ## end if ( my $class = Marpa::UrHTML::class() )
            $user_handler = $handlers_by_class->{ANY};
            if ( $trace_handlers and $user_handler ) {
                say {$trace_fh} +(
                    defined $element
                    ? "Resolved to user handler by element ($element)"
                    : 'Resolved to default user handler'
                );
            } ## end if ( $trace_handlers and $user_handler )
        } ## end GET_USER_HANDLER:

        if ( defined $user_handler ) {
            return [
                [   VALUED_SPAN => $first_token_id,
                    $last_token_id, $user_handler->(),
                    $per_node_data
                ]
            ];
        } ## end if ( defined $user_handler )

        my $doc          = $self->{doc};
        my @tdesc_result = ();

        my $first_token_id_in_current_span;
        my $last_token_id_in_current_span;

        TDESC: for my $tdesc ( @tdesc_list, ['FINAL'] ) {

            my $next_tdesc;
            my $first_token_id;
            my $last_token_id;
            PARSE_TDESC: {
                my $ref_type = ref $tdesc;
                if ( not $ref_type or $ref_type ne 'ARRAY' ) {
                    $next_tdesc = $tdesc;
                    last PARSE_TDESC;
                }
                given ( $tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] ) {
                    when ('POINT') { break; }
                    when ('VALUED_SPAN') {
                        if (not defined(
                                my $value = $tdesc->[
                                    Marpa::UrHTML::Internal::TDesc::Element::VALUE
                                ]
                            )
                            )
                        {
                            #<<< As of 2009-11-22 pertidy cycles on this
                            $first_token_id = $tdesc->[
                                Marpa::UrHTML::Internal::TDesc::START_TOKEN ];
                            $last_token_id =
                                $tdesc
                                ->[ Marpa::UrHTML::Internal::TDesc::END_TOKEN
                                ];
                            #>>>
                            break;    # last PARSE_TDESC;
                        } ## end if ( not defined( my $value = $tdesc->[ ...]))
                        $next_tdesc = $tdesc;
                    } ## end when ('VALUED_SPAN')
                    when ('FINAL') {
                        $next_tdesc = $tdesc;
                    }
                    when ('UNVALUED_SPAN') {
                        $first_token_id = $tdesc
                            ->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];
                        $last_token_id = $tdesc
                            ->[Marpa::UrHTML::Internal::TDesc::END_TOKEN];
                    } ## end when ('UNVALUED_SPAN')
                    default {
                        Marpa::exception("Unknown text description type: $_");
                    }
                } ## end given
            } ## end PARSE_TDESC:

            if ( defined $first_token_id and defined $last_token_id ) {
                if ( defined $first_token_id_in_current_span ) {
                    if ( $first_token_id
                        <= $last_token_id_in_current_span + 1 )
                    {
                        $last_token_id_in_current_span = $last_token_id;
                        next TDESC;
                    } ## end if ( $first_token_id <= ...)
                    push @tdesc_result,
                        [
                        'UNVALUED_SPAN',
                        $first_token_id_in_current_span,
                        $last_token_id_in_current_span
                        ];
                } ## end if ( defined $first_token_id_in_current_span )
                $first_token_id_in_current_span = $first_token_id;
                $last_token_id_in_current_span  = $last_token_id;
                next TDESC;
            } ## end if ( defined $first_token_id and defined $last_token_id)

            if ( defined $next_tdesc ) {
                if ( defined $first_token_id_in_current_span ) {
                    push @tdesc_result,
                        [
                        'UNVALUED_SPAN',
                        $first_token_id_in_current_span,
                        $last_token_id_in_current_span
                        ];

                    $first_token_id_in_current_span =
                        $last_token_id_in_current_span = undef;
                } ## end if ( defined $first_token_id_in_current_span )
                my $ref_type = ref $next_tdesc;

                last TDESC
                    if $ref_type eq 'ARRAY'
                        and
                        $next_tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] eq
                        'FINAL';
                push @tdesc_result, $next_tdesc;
            } ## end if ( defined $next_tdesc )

        } ## end for my $tdesc ( @tdesc_list, ['FINAL'] )

        return \@tdesc_result;
    };
} ## end sub create_tdesc_handler

sub wrap_user_tdesc_handler {
    my ( $user_handler, $per_node_data ) = @_;

    return sub {
        my ( $dummy, @tdesc_lists ) = @_;
        my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
        local $Marpa::UrHTML::Internal::TDESC_LIST = \@tdesc_list;
        my @token_ids = sort { $a <=> $b } grep {defined} map {
            @{$_}[
                Marpa::UrHTML::Internal::TDesc::START_TOKEN,
                Marpa::UrHTML::Internal::TDesc::END_TOKEN
                ]
        } @tdesc_list;

        my $first_token_id = $token_ids[0];
        my $last_token_id  = $token_ids[-1];
        $per_node_data //= {};
        $per_node_data->{first_token_id} = $first_token_id;
        $per_node_data->{last_token_id}  = $last_token_id;
        local $Marpa::UrHTML::Internal::PER_NODE_DATA = $per_node_data;

        return [
            [   VALUED_SPAN => $first_token_id,
                $last_token_id, $user_handler->(),
                $per_node_data
            ]
        ];
        }
} ## end sub wrap_user_tdesc_handler

sub setup_offsets {
    my ($self)     = @_;
    my $document   = $self->{document};
    my @rs_offsets = ();
    my $rs_offset  = 0;
    while ( ( $rs_offset = index ${$document}, "\n", $rs_offset ) >= 0 ) {
        push @rs_offsets, $rs_offset;
        $rs_offset++;
    }
    my %offsets = map { ( $rs_offsets[$_] => $_ ) } ( 0 .. $#rs_offsets );
    $self->{offset} = \%offsets;
    return 1;
} ## end sub setup_offsets

# Apparently a perlcritic bug as of 2009-11-22
## no critic (Subroutines::RequireFinalReturn)
sub earleme_to_offset {

    my ( $self, $token_offset ) = @_;
    my $html_parser_tokens = $self->{tokens};

    # Special start of file for undefined offset
    if ( not defined $token_offset ) {
        return ( 0, 1 ) if wantarray;
        return 0;
    }

    # Special case needed for a token offset after the last
    # token.  This happens with the EOF.
    my $offset;
    if ( $token_offset < 0 or $token_offset > $#{$html_parser_tokens} ) {
        $offset = length ${ $self->{document} };
    }
    else {
        $offset =
            $html_parser_tokens->[$token_offset]
            ->[Marpa::UrHTML::Internal::Token::END_OFFSET];
    }
    return $offset if not wantarray;

    my $last_rs = rindex ${ $self->{document} }, "\n", $offset;

    # lines are numbered starting at 1
    my $line;
    given ($last_rs) {
        when ( $_ <= 0 ) { $line = 1 }

        # if last_rs is the same as the offset, we are in that line
        when ($offset) {
            $line = $self->{offset}->{$last_rs} + 1
        }

        # If last_rs is different we are in the line after.
        # So add 2, because the value in the hash is the
        # 0-based number of the previous line,
        # and we want the 1-based number of the
        # current line.
        default {
            $line = $self->{offset}->{$last_rs} + 2
        }
    } ## end given

    return ( $offset, $line );
} ## end sub earleme_to_offset
## use critic

my %ARGS = (
    start       => q{'S',offset,offset_end,tagname,attr},
    end         => q{'E',offset,offset_end,tagname},
    text        => q{'T',offset,offset_end,is_cdata},
    process     => q{'PI',offset,offset_end},
    comment     => q{'C',offset,offset_end},
    declaration => q{'D',offset,offset_end},

    # options that default on
    unbroken_text => 1,
);

sub add_handlers {
    my ( $self, $handler_spec_list ) = @_;
    HANDLER_SPEC: for my $handler_spec ( @{$handler_spec_list} ) {
        my $element;
        my $id;
        my $class;
        my $pseudo_class;
        my $action;
        PARSE_HANDLER_SPEC: {
            my $ref_type = ref $handler_spec;
            if ( not defined $ref_type ) {
                Marpa::exception('undefined handler specification');
            }
            if ( $ref_type eq 'ARRAY' ) {
                my $specifier;
                ( $specifier, $action ) = @{$handler_spec};
                Marpa::exception('empty handler specification is not allowed')
                    if not $specifier;

                ( $element, $id ) =
                       ( $specifier =~ /\A ([^#]*) [#] (.*) \z/xms )
                    or ( $element, $class ) =
                       ( $specifier =~ /\A ([^.]*) [.] (.*) \z/xms )
                    or ( $element, $pseudo_class ) =
                    ( $specifier =~ /\A ([^:]*) [:] (.*) \z/xms )
                    or $element = $specifier;
                if ( $pseudo_class
                    and not $pseudo_class ~~
                    [qw(TOP COMMENT PROLOG TRAILER PCDATA CRUFT)] )
                {
                    Marpa::exception(
                        qq{pseudoclass "$pseudo_class" is not known:\n},
                        "Specifier was $specifier\n" );
                } ## end if ( $pseudo_class and not $pseudo_class ~~ [...])
                if ( $pseudo_class and $element ) {
                    Marpa::exception(
                        qq{pseudoclass "$pseudo_class" may not have an element specified:\n},
                        "Specifier was $specifier\n"
                    );
                } ## end if ( $pseudo_class and $element )
                last PARSE_HANDLER_SPEC;
            } ## end if ( $ref_type eq 'ARRAY' )
            if ( $ref_type eq 'HASH' ) {
                $element      = $handler_spec->{element};
                $id           = $handler_spec->{id};
                $class        = $handler_spec->{class};
                $pseudo_class = $handler_spec->{pseudo_class};
                $action       = $handler_spec->{action};
                last PARSE_HANDLER_SPEC;
            } ## end if ( $ref_type eq 'HASH' )
            Marpa::exception(
                'handler specification must be ref to ARRAY or HASH');
        } ## end PARSE_HANDLER_SPEC:
        $element = (not $element or $element eq q{*}) ? 'ANY' : lc $element;
        if ( defined $pseudo_class ) {
            $self->{user_handlers_by_pseudo_class}->{$element}
                ->{$pseudo_class} = $action;
            next HANDLER_SPEC;
        }
        if ( defined $id ) {
            $self->{user_handlers_by_id}->{$element}->{ lc $id } = $action;
            next HANDLER_SPEC;
        }
        $class = defined $class ? lc $class : 'ANY';
        $self->{user_handlers_by_class}->{$element}->{$class} = $action;

    } ## end for my $handler_spec ( @{$handler_spec_list} )

    return 1;
} ## end sub add_handlers

sub Marpa::UrHTML::new {
    my ( $class, @hash_args ) = @_;
    my $self = bless {}, $class;
    $self->{trace_fh} = \*STDERR;
    for my $hash_arg (@hash_args) {
        for my $key ( keys %{$hash_arg} ) {
            given ($key) {
                when (
                    [   qw(trace_fh trace_values trace_handlers trace_actions
                            trace_conflicts
                            trace_ambiguity trace_rules trace_QDFA
                            trace_earley_sets trace_terminals trace_cruft)
                    ]
                    )
                {
                    $self->{$_} = $hash_arg->{$_}
                } ## end when ( [ ...])
                when ('handlers') {
                    Marpa::UrHTML::Internal::add_handlers( $self,
                        $hash_arg->{$_} )
                }
                default {
                    Marpa::exception("Unknown option: $_");
                }
            } ## end given
        } ## end for my $key ( keys %{$hash_arg} )
    } ## end for my $hash_arg (@hash_args)
    return $self;
} ## end sub Marpa::UrHTML::new

# block_element is for block-level ONLY elements.
# head is for anything legal inside the HTML header.
# Note that isindex can be both a head element and
# and block level element in the body.
# ISINDEX is classified as a head_element
%Marpa::UrHTML::Internal::ELEMENT_TYPE = (
    (   map { $_ => 'block_element' }
            qw(
            h1 h2 h3 h4 h5 h6
            ul ol dir menu
            pre
            p dl div center
            noscript noframes
            blockquote form hr
            table fieldset address
            )
    ),
    (   map { $_ => 'head_element' }
            qw(
            script style meta link object title isindex base
            )
    ),
    ( map { $_ => 'list_item_element' } qw( li dd dt ) ),
    ( map { $_ => 'table_cell_element' } qw( td th ) ),
    ( map { $_ => 'table_row_element' } qw( tr ) ),
);

@Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS = qw(
    E_html
    E_body
    S_table
    E_head
    E_table
    E_tbody
    E_tr
    E_td
    S_td
    S_tr
    S_tbody
    S_head
    S_body
    S_html
);
%Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS = ();
for my $rank ( 0 .. $#Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS ) {
    $Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS{
        $Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS[$rank] } = $rank;
}

my @SGML_rh_sides = qw(D comment PI);

@Marpa::UrHTML::Internal::CORE_RULES = (
    { lhs => 'cruft',   rhs => ['CRUFT'],  action => '!CRUFT_handler' },
    { lhs => 'comment', rhs => ['C'],      action => '!COMMENT_handler' },
    { lhs => 'pcdata',  rhs => ['PCDATA'], action => '!PCDATA_handler' },
);

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'SGML_item', rhs => [$_] } } @SGML_rh_sides;

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'SGML_flow_item', rhs => [$_] } }
    qw(SGML_item WHITESPACE cruft);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'SGML_flow', rhs => ['SGML_flow_item'], min => 0 };

@Marpa::UrHTML::Internal::CORE_TERMINALS =
    qw(C D PI CRUFT CDATA PCDATA WHITESPACE EOF );

push @Marpa::UrHTML::Internal::CORE_TERMINALS,
    keys %Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS;

no strict 'refs';
*{'Marpa::UrHTML::Internal::default_action'} = create_tdesc_handler();
use strict;

push @Marpa::UrHTML::Internal::CORE_RULES,
    (
    {   lhs    => 'document',
        rhs    => [qw(prolog root trailer EOF)],
        action => '!TOP_handler',
    },
    {   lhs    => 'prolog',
        rhs    => ['SGML_flow'],
        action => '!PROLOG_handler',
    },
    {   lhs => 'trailer',
        rhs => ['SGML_flow'],
    },
    {   lhs    => 'root',
        rhs    => [qw(S_html Contents_root E_html)],
        action => '!ELE_html',
    },
    {   lhs => 'Contents_root',
        rhs => [qw(SGML_flow head SGML_flow body SGML_flow)],
    },
    {   lhs    => 'head',
        rhs    => [qw(S_head Contents_head E_head)],
        action => '!ELE_head',
    },
    {   lhs => 'Contents_head',
        rhs => ['head_item'],
        min => 0,
    },
    {   lhs    => 'body',
        rhs    => [qw(S_body flow E_body)],
        action => '!ELE_body',
    },
    {   lhs    => 'ELE_table',
        rhs    => [qw(S_table table_flow E_table)],
        action => '!ELE_table',
    },
    {   lhs    => 'ELE_tbody',
        rhs    => [qw(S_tbody table_section_flow E_tbody)],
        action => '!ELE_tbody',
    },
    {   lhs    => 'ELE_tr',
        rhs    => [qw(S_tr table_row_flow E_tr)],
        action => '!ELE_tr',
    },
    {   lhs    => 'ELE_td',
        rhs    => [qw(S_td flow E_td)],
        action => '!ELE_td',
    },
    { lhs => 'flow', rhs => ['flow_item'], min => 0 },
    );

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'flow_item', rhs => [$_] } }
    qw(cruft SGML_item ELE_table list_item_element head_element block_element inline_element WHITESPACE CDATA pcdata);

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'head_item', rhs => [$_] } }
    qw(head_element cruft WHITESPACE SGML_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'inline_flow', rhs => ['inline_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'inline_flow_item', rhs => [$_] } }
    qw(pcdata_flow_item inline_element);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'pcdata_flow', rhs => ['pcdata_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'pcdata_flow_item', rhs => [$_] } }
    qw(CDATA pcdata cruft WHITESPACE SGML_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'Contents_select', rhs => ['select_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'select_flow_item', rhs => [$_] } }
    qw(ELE_optgroup ELE_option SGML_flow_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'Contents_optgroup', rhs => ['optgroup_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'optgroup_flow_item', rhs => [$_] } }
    qw(ELE_option SGML_flow_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'list_item_flow', rhs => ['list_item_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'list_item_flow_item', rhs => [$_] } }
    qw(cruft SGML_item head_element block_element inline_element WHITESPACE CDATA pcdata);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'Contents_colgroup', rhs => ['colgroup_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'colgroup_flow_item', rhs => [$_] } }
    qw(ELE_col SGML_flow_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'table_row_flow', rhs => ['table_row_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'table_row_flow_item', rhs => [$_] } }
    qw(ELE_th ELE_td SGML_flow_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    {
    lhs => 'table_section_flow',
    rhs => ['table_section_flow_item'],
    min => 0
    };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'table_section_flow_item', rhs => [$_] } }
    qw(table_row_element SGML_flow_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'table_row_element', rhs => ['ELE_tr'] };

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'table_flow', rhs => ['table_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'table_flow_item', rhs => [$_] } }
    qw(
    ELE_colgroup ELE_thead ELE_tfoot ELE_tbody
    ELE_caption ELE_col SGML_flow_item
);

push @Marpa::UrHTML::Internal::CORE_RULES, { lhs => 'empty', rhs => [], };

%Marpa::UrHTML::Internal::EMPTY_ELEMENT = map { $_ => 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param);

%Marpa::UrHTML::Internal::CONTENTS = (
    'p'        => 'inline_flow',
    'select'   => 'Contents_select',
    'option'   => 'pcdata_flow',
    'optgroup' => 'Contents_optgroup',
    'dt'       => 'inline_flow',
    'dd'       => 'list_item_flow',
    'li'       => 'list_item_flow',
    'colgroup' => 'Contents_colgroup',
    'thead'    => 'table_section_flow',
    'tfoot'    => 'table_section_flow',
    'tbody'    => 'table_section_flow',
    'table'    => 'table_flow',
    ( map { $_ => 'empty' } keys %Marpa::UrHTML::Internal::EMPTY_ELEMENT ),
);

sub Marpa::UrHTML::parse {
    my ( $self, $document_ref ) = @_;

    my %start_tags = ();
    my %end_tags   = ();

    Marpa::exception(
        "parse() already run on this object\n",
        'For a new parse, create a new object'
    ) if $self->{document};

    my $trace_cruft     = $self->{trace_cruft};
    my $trace_terminals = $self->{trace_terminals} // 0;
    my $trace_conflicts = $self->{trace_conflicts};
    my $trace_fh        = $self->{trace_fh};
    my $ref_type        = ref $document_ref;
    Marpa::exception(
        'Arg to parse() must be ref to string' )
        if not $ref_type
            or $ref_type ne 'SCALAR';

    my %pull_parser_args;
    my $document = $pull_parser_args{doc} = $self->{document} = $document_ref;
    my $pull_parser = HTML::PullParser->new( %pull_parser_args, %ARGS )
        || Carp::croak('Could not create pull parser');

    Marpa::UrHTML::Internal::setup_offsets($self);
    my @tokens = ();

    my %terminals = map { $_ => 1 } @Marpa::UrHTML::Internal::CORE_TERMINALS;
    my %optional_terminals = %Marpa::UrHTML::Internal::CORE_OPTIONAL_TERMINALS;
    my @html_parser_tokens = ();
    my @marpa_tokens       = ();
    while ( my $html_parser_token = $pull_parser->get_token ) {
        my $token_number = scalar @html_parser_tokens;
        push @html_parser_tokens, $html_parser_token;
        given ( $html_parser_token->[0] ) {
            when ('T') {
                my ( $offset, $offset_end, $is_cdata ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                push @marpa_tokens,
                    [
                    (   substr(
                            ${$document}, $offset,
                            ( $offset_end - $offset )
                            ) =~ / \A \s* \z /xms ? 'WHITESPACE'
                        : $is_cdata ? 'CDATA'
                        : 'PCDATA'
                    ),
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('T')
            when ('S') {
                my ( $offset, $offset_end, $tag_name ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                $start_tags{$tag_name}++;
                my $terminal = "S_$tag_name";
                $terminals{$terminal}++;
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('S')
            when ('E') {
                my ( $offset, $offset_end, $tag_name ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                $end_tags{$tag_name}++;
                my $terminal = "E_$tag_name";
                $terminals{$terminal}++;
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('E')
            when ( [qw(C D)] ) {
                my ( $offset, $offset_end ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                push @marpa_tokens,
                    [
                    $_, [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( [qw(C D)] )
            when ( ['PI'] ) {
                my ( $offset, $offset_end ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                push @marpa_tokens,
                    [
                    $_, [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( ['PI'] )
            default { Carp::croak("Unprovided-for event: $_") }
        } ## end given
    } ## end while ( my $html_parser_token = $pull_parser->get_token)

    # Points AFTER the last HTML
    # Parser token.
    # The other logic needs to be ready for this.
    push @marpa_tokens, [ 'EOF', [ ['POINT'] ] ];

    $pull_parser = undef;    # conserve memory

    my @rules     = @Marpa::UrHTML::Internal::CORE_RULES;
    my @terminals = keys %terminals;

    my %pseudo_class_element_actions = ();
    my %element_actions = ();

    # Special cases which are dealt with elsewhere.
    # As of now the only special cases are elements with optional
    # start and end tags
    for my $special_element (qw(html head body table tbody tr td)) {
        delete $start_tags{$special_element};
        $element_actions{"!ELE_$special_element"} = $special_element;
    }

    ELEMENT: for ( keys %start_tags ) {
        my $start_tag    = "S_$_";
        my $end_tag      = "E_$_";
        my $contents     = $Marpa::UrHTML::Internal::CONTENTS{$_} // 'flow';
        my $element_type = $Marpa::UrHTML::Internal::ELEMENT_TYPE{$_}
            // 'inline_element';

        push @rules,
            {
            lhs => $element_type,
            rhs => ["ELE_$_"],
            },
            {
            lhs    => "ELE_$_",
            rhs    => [ $start_tag, $contents, $end_tag ],
            action => "!ELE_$_",
            };

        # There may be no
        # end tag in the input.
        # This silences the warning.
        if ( not $terminals{$end_tag} ) {
            push @terminals, $end_tag;
            $terminals{$end_tag}++;
        }

        # Make each new optional terminal the highest ranking
        $optional_terminals{$end_tag} = keys %optional_terminals;

        $element_actions{"!ELE_$_"} = $_;
    } ## end for ( keys %start_tags )

    my %ok_as_cruft = ();

    EXPECTED_TERMINAL:
    for my $expected_terminal (
        keys %optional_terminals )
    {

        # When expecting start tags nothing is OK as cruft.
        next EXPECTED_TERMINAL if $expected_terminal =~ /^S_/xms;

        # When expecting implicit start tags nothing is OK as cruft.
        next EXPECTED_TERMINAL if $expected_terminal =~ /^IS_/xms;

        # "Non-structural" elements are OK as cruft.
        # "Non-structural" means not part of the logic for
        # those tags.
        # So for the OPTION elements
        # OPTION and OPTIONGROUP tags are structural
        # and nothing else with one exception:
        # The EOF tag is always structural.
        if ( $expected_terminal ~~ [qw(E_option)] ) {
            TERMINAL: for my $actual_terminal (@terminals) {
                next TERMINAL if $actual_terminal ~~ [
                    qw(EOF
                        E_optgroup E_option E_select
                        S_optgroup S_option S_select
                        )
                ];
                $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            } ## end for my $actual_terminal (@terminals)
            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal ~~ [qw(E_option)] )

        # For list item elements (LI, DD and DT)
        # EOF, list element tags
        # and list item element tags are structural.
        #
        # 2009-11-25  Changed this so that LI DD and DT
        # elements do not accept cruft.  This seems to
        # be better for dealing with crufty pages that
        # you actually encounter in real life.
        if ( $expected_terminal ~~ [qw(E_li E_dd E_dt)] ) {

            # TERMINAL: for my $actual_terminal (@terminals) {
            #    next TERMINAL if $actual_terminal ~~ [
            #        qw(EOF
            #            E_li E_dd E_dt
            #            S_li S_dd S_dt
            #            E_ol E_ul E_dl
            #            S_ol S_ul S_dl
            #            )
            #    ];
            #    $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            # } ## end for my $actual_terminal (@terminals)

            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal ~~ [qw(E_li E_dd E_dt)] )

        # Empty elements accept nothing as interior cruft
        next EXPECTED_TERMINAL
            if $expected_terminal ~~ /^E_/xms
                and $Marpa::UrHTML::Internal::EMPTY_ELEMENT{
                    substr $expected_terminal, 2 };

        # HEAD, COLGROUP and P elements do not accept interior cruft, instead
        # passing it along to the next element
        # Also don't allow interior cruft in an FONT element.
        next EXPECTED_TERMINAL if $expected_terminal ~~ [
            qw(
                E_head
                E_p
                E_font
                E_colgroup
                )
        ];

        # When expecting E_body, that is, when in the top body
        # flow, everything but an EOF or an E_html
        # is fine as cruft
        if ( $expected_terminal eq 'E_body' ) {
            TERMINAL: for my $actual_terminal (@terminals) {
                next TERMINAL if $actual_terminal ~~ [qw(EOF E_html)];
                $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            }
            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal eq 'E_body' )

        # TD TH and TR elements accept interior cruft, but since
        # their end tag is optional, it cannot be "structural".
        # And EOF is never allowed as cruft.
        if ( $expected_terminal ~~ [qw(E_td E_th E_tr)] ) {
            TERMINAL: for my $actual_terminal (@terminals) {
                next TERMINAL if $actual_terminal ~~ [
                    qw(EOF E_table
                        S_td _S_th S_tr S_tbody S_thead S_tfoot S_col S_caption S_colgroup
                        E_td _E_th E_tr E_tbody E_thead E_tfoot E_col E_caption E_colgroup
                        )
                ];
                $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            } ## end for my $actual_terminal (@terminals)
            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal ~~ [qw(E_td E_th E_tr)] )

        # TBODY, THEAD, TFOOT elements
        # must end at an EOF, at a TABLE end tag
        # or at the start tag of another table-section-level element
        # and will not accept a mismatched end tag as interior
        # cruft.
        # Other than that they are happy to accept interior cruft.
        if ( $expected_terminal ~~ [qw(E_tbody E_thead E_tfoot)] ) {
            TERMINAL: for my $actual_terminal (@terminals) {
                next TERMINAL if $actual_terminal ~~ [
                    qw(EOF E_table
                        S_tbody S_thead S_tfoot S_col S_caption S_colgroup
                        E_tbody E_thead E_tfoot E_col E_caption E_colgroup
                        )
                ];
                $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            } ## end for my $actual_terminal (@terminals)
            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal ~~ [qw(E_tbody E_thead E_tfoot)...])

        if ( $expected_terminal ~~ /^E_/xms ) {

            # Default for end tags
            # is to treat the element as non-empty,
            # and with the end tag required
            TERMINAL: for my $actual_terminal (@terminals) {
                next TERMINAL if $actual_terminal eq 'EOF';
                $ok_as_cruft{$expected_terminal}{$actual_terminal}++;
            }
            next EXPECTED_TERMINAL;
        } ## end if ( $expected_terminal ~~ /^E_/xms )

        default {

            # Should not get here
            Marpa::exception("Unprovided-for optional terminal: $expected_terminal");
        }

    } ## end for my $expected_terminal ( keys ...)

    my $grammar = Marpa::Grammar->new(
        {   rules     => \@rules,
            start     => 'document',
            terminals => \@terminals,

            inaccessible_ok => [
                qw(
                    Contents_colgroup Contents_optgroup Contents_select
                    ELE_caption ELE_col ELE_colgroup
                    ELE_optgroup ELE_option
                    ELE_tfoot ELE_thead
                    ELE_tbody E_tbody S_tbody
                    ELE_table E_table S_table
                    ELE_tr E_tr S_tr
                    ELE_td E_td S_td
                    colgroup_flow_item empty inline_flow inline_flow_item
                    list_item_flow list_item_flow_item optgroup_flow_item
                    table_row_element 
                    pcdata_flow pcdata_flow_item
                    select_flow_item
                    table_flow table_flow_item
                    table_row_flow table_row_flow_item
                    table_section_flow table_section_flow_item
                    )
            ],

            unproductive_ok => [
                qw(
                    ELE_caption ELE_col ELE_colgroup ELE_optgroup ELE_option
                    ELE_tfoot ELE_thead ELE_tr ELE_th
                    block_element head_element inline_element list_item_element
                    )
            ],

            default_action => 'Marpa::UrHTML::Internal::default_action',
            strip => 0,
        }
    );
    $grammar->precompute();

    if ( $self->{trace_rules} ) {
        say {$trace_fh} $grammar->show_rules();
    }
    if ( $self->{trace_QDFA} ) {
        say {$trace_fh} $grammar->show_QDFA();
    }

    my $recce = Marpa::Recognizer->new(
        {   grammar           => $grammar,
            trace_terminals   => $self->{trace_terminals},
            trace_earley_sets => $self->{trace_earley_sets},
            trace_values      => $self->{trace_values},
            trace_actions     => $self->{trace_actions},
            clone             => 0,
        }
    );

    if ( $ENV{TRACE_SIZE} ) {
        say 'newly created recce size: ', total_size($recce);
    }

    $self->{recce}  = $recce;
    $self->{tokens} = \@html_parser_tokens;
    my ( $current_earleme, $expected_terminals ) = $recce->status();
    MARPA_TOKEN: for my $marpa_token (@marpa_tokens) {
        my $is_virtual_token = 1;
        my $actual_terminal = $marpa_token->[0];
        if ($trace_terminals) {
            say {$trace_fh} 'Literal Token: ', $actual_terminal;
        }

        # This counter prevents bugs in the grammar from becoming
        # infinite loops.  If and when the grammar is settled,
        # a proof should be made that all cases are accounted for.
        my $virtual_counter = 0;

        VIRTUAL_TOKEN: while ($is_virtual_token) {

            my $token_to_add;
            FIND_VIRTUAL_TOKEN: {

                ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
                if ( $virtual_counter++ > 10 ) {
                    say {$trace_fh} 
                        "Added 100 virtual tokens without adding the real one\n",
                        qq{The real token is "$actual_terminal"\n},
                        "This is probably a bug in the grammar for HTML" ;
                    $token_to_add     = $marpa_token;
                    $is_virtual_token = 0;
                    last FIND_VIRTUAL_TOKEN;
                } ## end if ( $virtual_counter++ > 10 )
                ## use critic

                if ( $actual_terminal ~~ $expected_terminals ) {
                    $token_to_add     = $marpa_token;
                    $is_virtual_token = 0;
                    last FIND_VIRTUAL_TOKEN;
                }

                my $virtual_terminal;
                my @virtuals_expected = sort {
                    $optional_terminals{$a} <=> $optional_terminals{$b}
                    }
                    grep { defined $optional_terminals{$_} }
                    @{$expected_terminals};
                if ($trace_conflicts) {
                    say {$trace_fh} 'Conflict of virtual choices';
                    say {$trace_fh} "Actual Token is $actual_terminal";
                    say {$trace_fh} +( scalar @virtuals_expected ),
                        ' virtual terminals expected: ', join q{ },
                        @virtuals_expected;
                } ## end if ($trace_conflicts)

                LOOKAHEAD_VIRTUAL_TERMINAL:
                while ( my $candidate = pop @virtuals_expected ) {

                    # Don't start a new table cell as a way of dealing with
                    # A new row or table section
                    if (    $candidate eq 'S_td'
                        and $actual_terminal ~~
                        [qw(S_tr S_thead S_tfoot S_tbody )] )
                    {
                        next LOOKAHEAD_VIRTUAL_TERMINAL;
                    } ## end if ( $candidate eq 'S_td' and $actual_terminal ~~ [...])

                    # and end tag for a row, cell, table section
                    # or as a way of dealing with EOF
                    if ($candidate ~~ [qw(S_tr S_td S_tbody)]
                        and $actual_terminal ~~ [
                            qw(E_th E_td E_tr E_thead E_tfoot E_tbody E_table EOF)
                        ]
                        )
                    {
                        next LOOKAHEAD_VIRTUAL_TERMINAL;
                    } ## end if ( $candidate ~~ [qw(S_tr S_td S_tbody)] and ...)

                    # Start an implied table only if the next token is one which
                    # can only occur inside a table
                    if ($candidate eq 'S_table'
                        and not $actual_terminal ~~ [
                            qw(
                                S_caption S_col S_colgroup S_thead S_tfoot
                                S_tbody S_tr S_th S_td
                                E_caption E_col E_colgroup E_thead E_tfoot
                                E_tbody E_tr E_th E_td
                                E_table
                                )
                        ]
                        )
                    {
                        next LOOKAHEAD_VIRTUAL_TERMINAL;
                    } ## end if ( $candidate eq 'S_table' and not ...)

                    $virtual_terminal = $candidate;
                    last LOOKAHEAD_VIRTUAL_TERMINAL;

                } ## end while ( my $candidate = pop @virtuals_expected )

                if ($trace_terminals) {
                    say {$trace_fh} 'Converting Token: ', $actual_terminal;
                    if ( defined $virtual_terminal ) {
                        say {$trace_fh} 'Candidate as Virtual Token: ',
                            $virtual_terminal;
                    }
                } ## end if ($trace_terminals)

                # Depending on the expected (optional or virtual)
                # terminal and the actual
                # terminal, we either want to add the actual one as cruft, or add
                # the virtual one to move on in the parse.

                if ( $trace_terminals > 1 and defined $virtual_terminal ) {
                    say {$trace_fh}
                        "OK as cruft when expecting $virtual_terminal: ",
                        join q{ }, keys %{ $ok_as_cruft{$virtual_terminal} };
                }

                if ( defined $virtual_terminal
                    and
                    not $ok_as_cruft{$virtual_terminal}{$actual_terminal} )
                {
                    my $tdesc_list = $marpa_token->[1];
                    my $first_tdesc_start_token =
                        $tdesc_list->[0]
                        ->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];
                    $token_to_add = [
                        $virtual_terminal,
                        [ [ 'POINT', $first_tdesc_start_token ] ]
                    ];
                    last FIND_VIRTUAL_TOKEN;
                } ## end if ( defined $virtual_terminal and not $ok_as_cruft{...})

                if ($trace_terminals) {
                    say {$trace_fh} 'Adding actual token as cruft: ',
                        $actual_terminal;
                }

                # Cruft tokens are not virtual.
                # They are the real things, hacked up.
                $marpa_token->[0] = 'CRUFT';
                $token_to_add     = $marpa_token;
                $is_virtual_token = 0;
                if ($trace_cruft) {
                    my $cruft_earleme = $current_earleme - 1;
                    if ( $cruft_earleme < 0 ) { $cruft_earleme = 0 }
                    my ( $offset, $line ) =
                        earleme_to_offset( $self, $cruft_earleme );
                    $line++
                        ;  # The convention is that line numbering starts at 1
                    say {$trace_fh} qq{Cruft at line $line: "},
                        ${ tdesc_list_to_literal( $self, $marpa_token->[1] )
                        },
                        q{"};
                } ## end if ($trace_cruft)
            } ## end FIND_VIRTUAL_TOKEN:

            if ($trace_terminals) {
                say {$trace_fh} 'Adding Token: ', $token_to_add->[0];
            }

            ( $current_earleme, $expected_terminals ) =
                $recce->tokens( [$token_to_add], 'predict' );
            if ( not defined $current_earleme ) {
                my $last_marpa_token = $recce->furthest();
                $last_marpa_token =
                      $last_marpa_token > $#marpa_tokens
                    ? $#marpa_tokens
                    : $last_marpa_token;
                my ( $furthest_offset, $furthest_offset_line ) =
                    Marpa::UrHTML::Internal::earleme_to_offset( $self,
                    $last_marpa_token );
                say Data::Dumper::Dumper( $recce->find_parse() );
                Marpa::exception(
                    "HTML parse exhausted at location $furthest_offset, line $furthest_offset_line"
                );
            } ## end if ( not defined $current_earleme )
        } ## end while ($is_virtual_token)
    } ## end for my $marpa_token (@marpa_tokens)

    if ($trace_terminals) {
        say {$trace_fh} 'at end of tokens, expecting: ', join q{ },
            @{$expected_terminals};
    }

    if ( $ENV{TRACE_SIZE} ) {
        say 'pre-strip recce size: ', total_size($recce);
        for my $ix ( 0 .. $#{$recce} ) {
            say "pre-strip recce size, element $ix: ",
                total_size( $recce->[$ix] );
        }
    } ## end if ( $ENV{TRACE_SIZE} )
    $recce->strip();    # Saves lots of memory

    if ( $ENV{TRACE_SIZE} ) {
        say 'post-strip recce size: ', total_size($recce);
        for my $ix ( 0 .. $#{$recce} ) {
            say "pre-strip recce size, element $ix: ",
                total_size( $recce->[$ix] );
        }
    } ## end if ( $ENV{TRACE_SIZE} )

    my %closure = (
        '!rank_is_zero'   => sub {0},
        '!rank_is_one'    => sub {1},
        '!rank_is_two'    => sub {2},
        '!rank_is_three'  => sub {3},
        '!rank_is_four'   => sub {4},
        '!rank_is_length' => sub { Marpa::length() },
        '!TOP_handler'    => (
            $self->{user_handlers_by_pseudo_class}->{ANY}->{TOP}
                // \&Marpa::UrHTML::Internal::default_top_handler
        ),
    );

    if ( defined $self->{user_handlers_by_class}->{ANY}->{ANY} ) {
        $closure{'!DEFAULT_ELE_handler'} =
            $self->{user_handlers_by_class}->{ANY}->{ANY};
    }

    PSEUDO_CLASS:
    for my $pseudo_class (
        qw(COMMENT PROLOG TRAILER PCDATA CRUFT))
    {
        my $pseudo_class_action =
            $self->{user_handlers_by_pseudo_class}->{ANY}->{$pseudo_class};
        my $pseudo_class_action_name = "!$pseudo_class" . '_handler';
        if ($pseudo_class_action) {
            $closure{$pseudo_class_action_name} =
                wrap_user_tdesc_handler($pseudo_class_action, { pseudo_class => $pseudo_class } );
            next PSEUDO_CLASS;
        }
        $closure{$pseudo_class_action_name} =
            \&Marpa::UrHTML::Internal::default_action;
    } ## end for my $pseudo_class (...)

    while ( my ( $element_action, $element ) = each %element_actions ) {
        $closure{$element_action} = create_tdesc_handler( $self, $element );
    }

    ELEMENT_ACTION:
    while ( my ( $element_action, $data ) =
        each %pseudo_class_element_actions )
    {

        # As of now, there are
        # no per-element pseudo-classes, and since I can't regression test
        # this logic any more, I'm commenting it out.
        Marpa::exception('per-element pseudo-classes not implemented');

        # my ( $pseudo_class, $element ) = @{$data};
        # my $pseudo_class_action =
        #    $self->{user_handlers_by_pseudo_class}->{$element}
        #    ->{$pseudo_class}
        #    // $self->{user_handlers_by_pseudo_class}->{ANY}->{$pseudo_class};
        # if ( defined $pseudo_class_action ) {
        #    $pseudo_class_action =
        #        wrap_user_tdesc_handler($pseudo_class_action);
        # }
        # $pseudo_class_action //= \&Marpa::UrHTML::Internal::default_action;
        # $closure{$element_action} = $pseudo_class_action;
    } ## end while ( my ( $element_action, $data ) = each ...)

    my $value = do {
        local $Marpa::UrHTML::Internal::PARSE_INSTANCE = $self;
        local $Marpa::UrHTML::INSTANCE                 = {};
        my $evaler = Marpa::Evaluator->new(
            { recce => $recce, clone => 0, closures => \%closure, } );

        Marpa::exception('No parse') if not $evaler;

        if ( $ENV{TRACE_SIZE} ) {
            say 'pre-undef recce size: ', total_size($recce);
            for my $ix ( 0 .. $#{$recce} ) {
                say "pre-undef recce size, element $ix: ",
                    total_size( $recce->[$ix] );
            }
        } ## end if ( $ENV{TRACE_SIZE} )

        $recce = undef;    # conserve memory

        if ( $ENV{TRACE_SIZE} ) {
            say 'post-undef recce size: ', total_size($recce);
        }

        if ( my $verbose = $self->{trace_ambiguity} ) {
            say $evaler->show_ambiguity($verbose);
        }

        if ( not $evaler ) {
            my $last_marpa_token = $recce->furthest();
            $last_marpa_token =
                  $last_marpa_token > $#marpa_tokens
                ? $#marpa_tokens
                : $last_marpa_token;
            my $furthest_offset =
                Marpa::UrHTML::Internal::earleme_to_offset( $self,
                $last_marpa_token );

            my $last_good_earleme = $recce->find_parse();
            say 'last_good_earleme=',
                Data::Dumper::Dumper($last_good_earleme);
            my $last_good_offset =
                Marpa::UrHTML::Internal::earleme_to_offset( $self,
                $last_good_earleme );
            say 'last_good_offset=', Data::Dumper::Dumper($last_good_offset);

            # 100 characters --
            # the amount of context to put in the error message
            #
            ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
            say 'last good at ',
                ( substr ${$document}, $last_good_offset, 100 );
            ## use critic

            say Data::Dumper::Dumper( $recce->find_parse() );

            Marpa::exception( 'HTML parse exhausted at location ',
                $furthest_offset );
        } ## end if ( not $evaler )
        $evaler->value;
    };
    Marpa::exception('undef returned') if not defined $value;
    return $value;

} ## end sub Marpa::UrHTML::parse

1;

__END__

=head1 NAME

Marpa::UrHTML - Element-level HTML Parser

=head1 SYNOPSIS

Coming Soon!

=head1 DESCRIPTION

Coming Soon!

=head1 AUTHOR

Jeffrey Kegler

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parse-marpa at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Marpa>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

=begin Marpa::Test::Display:

## skip display

=end Marpa::Test::Display:

    perldoc Marpa
    
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marpa>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marpa>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa>

=item * Search CPAN

L<http://search.cpan.org/dist/Marpa>

=back

=head1 ACKNOWLEDGMENTS

The starting template for this code was
HTML::TokeParser, by Gisle Aas.

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2009 Jeffrey Kegler, all rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl 5.10.0.

=cut
