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

use Smart::Comments '-ENV';

### <where> Using smart comments ...

package Marpa::UrHTML::Internal;

use Marpa::Internal;

BEGIN {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    use Devel::Size;
}

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

sub tdesc_list_to_text {
    my ( $self, $tdesc_list ) = @_;
    my $text     = q{};
    my $document = $self->{document};
    my $tokens   = $self->{tokens};
    TDESC: for my $tdesc ( @{$tdesc_list} ) {
        given ( $tdesc->[Marpa::UrHTML::Internal::TDesc::TYPE] ) {
            when ('EMPTY') { break; }
            when ('ELE') {
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
                break
                    if not defined(
                            my $first_token_id =
                                $tdesc
                                ->[Marpa::UrHTML::Internal::TDesc::START_TOKEN
                                ]
                    );

                # next TDESC if no last token id
                break
                    if not defined(
                            my $last_token_id =
                                $tdesc
                                ->[Marpa::UrHTML::Internal::TDesc::END_TOKEN]
                    );

                my $offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::UrHTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::UrHTML::Internal::Token::END_OFFSET];
                $text .= substr ${$document}, $offset,
                    ( $end_offset - $offset );
            } ## end when ('ELE')
            when ('TOKEN_SPAN') {
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
            } ## end when ('TOKEN_SPAN')
            default {
                Marpa::exception(qq{Internal error: unknown tdesc type "$_"});
            }
        } ## end given
    } ## end for my $tdesc ( @{$tdesc_list} )
    return \$text;
} ## end sub tdesc_list_to_text

# Convert a list of text descriptions to text
sub default_top_handler {
    my ( $dummy, @tdesc_lists ) = @_;

    my $self = $Marpa::UrHTML::Internal::PARSE_INSTANCE;
    my @tdesc_list = map { @{$_} } grep { defined } @tdesc_lists;
    return tdesc_list_to_text( $self, \@tdesc_list );

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

        my @tdesc_list = map { @{$_} } grep { defined } @tdesc_lists;
        local $Marpa::UrHTML::Internal::TDESC_LIST = \@tdesc_list;
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
            my @tokens = sort { $a <=> $b } grep {defined} map {
                @{$_}[
                    Marpa::UrHTML::Internal::TDesc::START_TOKEN,
                    Marpa::UrHTML::Internal::TDesc::END_TOKEN
                    ]
            } @tdesc_list;
            local $Marpa::UrHTML::Internal::NODE_SCRATCHPAD = {};

            return [
                [ ELE => $tokens[0], $tokens[-1], $user_handler->() ] ];
        } ## end if ( defined $user_handler )

        my $doc          = $self->{doc};
        my @tdesc_result = ();

        my $last_token;
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
                    when ('EMPTY') { break; }
                    when ('ELE') {
                        if (not defined(
                                my $value = $tdesc->[
                                    Marpa::UrHTML::Internal::TDesc::Element::VALUE
                                ]
                            )
                            )
                        {
                            $first_token_id = $tdesc->[
                                Marpa::UrHTML::Internal::TDesc::START_TOKEN ];
                            $last_token_id =
                                $tdesc
                                ->[ Marpa::UrHTML::Internal::TDesc::END_TOKEN
                                ];
                            break;    # last PARSE_TDESC;
                        } ## end if ( not defined( my $value = $tdesc->[ ...]))
                        $next_tdesc = $tdesc;
                    } ## end when ('ELE')
                    when ('FINAL') {
                        $next_tdesc = $tdesc;
                    }
                    when ('TOKEN_SPAN') {
                        $first_token_id = $tdesc
                            ->[ Marpa::UrHTML::Internal::TDesc::START_TOKEN ];
                        $last_token_id = $tdesc
                            ->[ Marpa::UrHTML::Internal::TDesc::END_TOKEN ];
                    } ## end when ('TOKEN_SPAN')
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
                        'TOKEN_SPAN',
                        $first_token_id_in_current_span,
                        $last_token_id_in_current_span
                        ];
                } ## end if ( defined $first_token_id_in_current_span )
                $first_token_id_in_current_span = $first_token_id;
                $last_token_id_in_current_span  = $last_token_id;
                next TDESC;
            } ## end if ( defined $first_token_id )

            if ( defined $next_tdesc ) {
                if ( defined $first_token_id_in_current_span ) {
                    push @tdesc_result,
                        [
                        'TOKEN_SPAN',
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
        }
} ## end sub create_tdesc_handler

sub wrap_user_tdesc_handler {
    my ($user_handler) = @_;

    return sub {
        my ( $dummy, @tdesc_lists ) = @_;
        my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
        local $Marpa::UrHTML::Internal::TDESC_LIST = \@tdesc_list;
        my @tokens = sort { $a <=> $b } grep {defined} map {
                @{$_}[
                    Marpa::UrHTML::Internal::TDesc::START_TOKEN,
                    Marpa::UrHTML::Internal::TDesc::END_TOKEN
                    ]
            } @tdesc_list;
        local $Marpa::UrHTML::Internal::NODE_SCRATCHPAD = {};

        return [ [ ELE => $tokens[0], $tokens[-1], $user_handler->() ] ];
        }
} ## end sub wrap_user_tdesc_handler
        
sub setup_offsets {
    my ($self) = @_;
    my $document = $self->{document};
    my @rs_offsets = ();
    my $rs_offset = 0;
    while (($rs_offset = index ${$document}, "\n", $rs_offset) >= 0) {
        push @rs_offsets, $rs_offset;
        $rs_offset++;
    }
    my %offsets = map { ( $rs_offsets[$_] => $_ ) } ( 0 .. $#rs_offsets );
    $self->{offset} = \%offsets;
    return 1;
}

sub earleme_to_offset {
    my ( $self, $token_offset ) = @_;
    my $html_parser_tokens   = $self->{tokens};

    # Special start of file for undefined offset
    if (not defined $token_offset) {
        return (0, 1) if wantarray;
        return 0;
    }

    # Special case needed for a token offset after the last
    # token.  This happens with the EOF.
    my $offset;
    if ( $token_offset < 0 or $token_offset > $#{$html_parser_tokens} )
    {
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

    return ($offset, $line);
}

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
                ( $element, $id ) =
                       ( $specifier =~ /\A ([^#]*) [#] (.*) \z/xms )
                    or ( $element, $class ) =
                       ( $specifier =~ /\A ([^.]*) [.] (.*) \z/xms )
                    or ( $element, $pseudo_class ) =
                    ( $specifier =~ /\A ([^:]*) [:] (.*) \z/xms )
                    or $element = $specifier;
                if ($pseudo_class
                    and not $pseudo_class ~~ [
                        qw(TOP PROLOG ROOT HEAD BODY TRAILER TERMINATED UNTERMINATED CRUFT)
                    ]
                    )
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
                } ## end if ( $pseudo_class and defined $element )
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
        $element = $element ? lc $element : 'ANY';
        if ( defined $pseudo_class ) {
            $self->{user_handlers_by_pseudo_class}->{$element}->{ $pseudo_class } = $action;
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
                            trace_ambiguity trace_rules trace_QDFA
                            trace_earley_sets trace_terminals trace_cruft)
                    ]
                    )
                {
                    $self->{$_} = $hash_arg->{$_}
                } ## end when ( [ qw(trace_fh trace_values trace_handlers...)])
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

# These are block-level ONLY elements.
# Note that isindex can be both a head element and
# and block level element in the body.
# It is not present in this list
%Marpa::UrHTML::Internal::BLOCK_ELEMENT = map { $_ => 1 } qw(
    h1 h2 h3 h4 h5 h6
    ul ol dir menu
    pre
    p dl div center
    noscript noframes
    blockquote form hr
    table fieldset address
);

# Note that isindex can be both a head element and
# and block level element in the body.
%Marpa::UrHTML::Internal::HEAD_ELEMENT = map { $_ => 1 } qw(
    script style meta link object title isindex base
);

%Marpa::UrHTML::Internal::EMPTY_ELEMENT = map { $_ => 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param
);

%Marpa::UrHTML::Internal::OPTIONAL_TERMINALS =
    # qw( html head body tbody );
    map { ( "S_$_" => 1, "E_$_" => 1 ) } qw( html head body );

my @SGML_rh_sides = qw(D C PI);

@Marpa::UrHTML::Internal::CORE_RULES =
    map { { lhs => 'SGML_item', rhs => [$_] } } @SGML_rh_sides;

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'SGML_flow_item', rhs => [$_] } }
    qw(SGML_item WHITESPACE CRUFT);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'SGML_flow', rhs => ['SGML_flow_item'], min => 0 };

@Marpa::UrHTML::Internal::CORE_TERMINALS =
    ( @SGML_rh_sides, qw(CRUFT CDATA PCDATA WHITESPACE EOF ) );

push @Marpa::UrHTML::Internal::CORE_TERMINALS, keys %Marpa::UrHTML::Internal::OPTIONAL_TERMINALS;

no strict 'refs';
*{'Marpa::UrHTML::Internal::default_action'} = create_tdesc_handler();
use strict;

push @Marpa::UrHTML::Internal::CORE_RULES,
    (
    {   lhs    => 'document',
        rhs    => [qw(prolog root trailer EOF)],
        action => '!TOP_handler',
    },
    {   lhs            => 'prolog',
        rhs            => ['SGML_flow'],
        action         => '!PROLOG_handler',
    },
    {   lhs            => 'trailer',
        rhs            => ['SGML_flow'],
    },
    {   lhs    => 'root',
        rhs    => [qw(S_html Contents_root E_html)],
        action => '!ROOT_handler',
    },
    {   lhs    => 'Contents_root',
        rhs    => [qw(SGML_flow head SGML_flow body SGML_flow)],
    },
    {   lhs    => 'head',
        rhs    => [qw(S_head Contents_head E_head)],
        action => '!HEAD_handler',
    },
    {   lhs    => 'Contents_head',
        rhs    => ['head_item'],
        min    => 0,
    },
    {   lhs    => 'body',
        rhs    => [qw(S_body flow E_body)],
        action => '!BODY_handler',
    },
    { lhs => 'flow', rhs => ['flow_item'], min => 0 },
    {   lhs    => 'cruft',
        rhs    => ['CRUFT'],
        action => '!CRUFT_handler',
    },
    );

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'flow_item', rhs => [$_] } }
    qw(block_element head_item inline_element CDATA PCDATA);

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'head_item', rhs => [$_] } }
    qw(cruft WHITESPACE SGML_item);

push @Marpa::UrHTML::Internal::CORE_RULES,
    { lhs => 'inline_flow', rhs => ['inline_flow_item'], min => 0 };

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'inline_flow_item', rhs => [$_] } }
    qw(CDATA PCDATA cruft WHITESPACE SGML_item inline_element);

%Marpa::UrHTML::Internal::CONTENTS = (
   'p' => 'inline_flow'
);

my %start_tags = ();
my %end_tags   = ();

sub Marpa::UrHTML::parse {
    my ( $self, $document_ref ) = @_;
    my $trace_cruft     = $self->{trace_cruft};
    my $trace_terminals = $self->{trace_terminals};
    my $trace_fh        = $self->{trace_fh};
    my $ref_type        = ref $document_ref;
    Marpa::exception(
        'Arg to ' . __PACKAGE__ . '::parse must be ref to string' )
        if not $ref_type
            or $ref_type ne 'SCALAR';

    my %pull_parser_args;
    my $document = $pull_parser_args{doc} = $self->{document} = $document_ref;
    my $pull_parser = HTML::PullParser->new( %pull_parser_args, %ARGS )
        || Carp::croak('Could not create pull parser');

    Marpa::UrHTML::Internal::setup_offsets($self);
    my @tokens = ();

    my %terminals = map { $_ => 1 } @Marpa::UrHTML::Internal::CORE_TERMINALS;
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
                    [ [ 'TOKEN_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('T')
            when ('S') {
                my ( $offset, $offset_end, $tag_name ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                $start_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                $terminals{$terminal}++;
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'TOKEN_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('S')
            when ('E') {
                my ( $offset, $offset_end, $tag_name ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                $end_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                if (not
                    defined $Marpa::UrHTML::Internal::EMPTY_ELEMENT{$tag_name}
                    )
                {
                    $terminals{$terminal}++;
                } ## end if ( not defined ...)
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'TOKEN_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('E')
            when ( [qw(C D)] ) {
                my ( $offset, $offset_end ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                push @marpa_tokens,
                    [
                    $_, [ [ 'TOKEN_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( [qw(C D)] )
            when ( ['PI'] ) {
                my ( $offset, $offset_end ) =
                    @{$html_parser_token}[ 1 .. $#{$html_parser_token} ];
                push @marpa_tokens,
                    [
                    $_, [ [ 'TOKEN_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( ['PI'] )
            default { Carp::croak("Unprovided-for event: $_") }
        } ## end given
    } ## end while ( my $html_parser_token = $pull_parser->get_token)

    # Points AFTER the last HTML
    # Parser token.
    # The other logic needs to be ready for this.
    push @marpa_tokens,
        [ 'EOF', [ [ 'EMPTY' ] ] ];

    $pull_parser = undef;    # conserve memory

    my @rules     = @Marpa::UrHTML::Internal::CORE_RULES;
    my @terminals = keys %terminals;

    my %element_actions              = ();
    my %pseudo_class_element_actions = ();

    # Some HTML tags are special and
    # are dealt with elsewhere
    delete $start_tags{html};
    delete $start_tags{head};
    delete $start_tags{body};

    ELEMENT: for ( keys %start_tags ) {
        when ( defined $Marpa::UrHTML::Internal::EMPTY_ELEMENT{$_} ) {
            my $this_element = "ELE_$_";
            push @rules,
                {
                lhs => $this_element,
                rhs => ["S_$_"],
                };
            my $element_type =
                  $Marpa::UrHTML::Internal::HEAD_ELEMENT{$_} ? 'head_item'
                : $Marpa::UrHTML::Internal::BLOCK_ELEMENT{$_}
                ? 'block_element'
                : 'inline_element';
            push @rules,
                {
                lhs    => $element_type,
                rhs    => [$this_element],
                action => "!ELE_$_",
                };
            $element_actions{"!ELE_$_"} = $_;
        } ## end when ( defined $Marpa::UrHTML::Internal::EMPTY_ELEMENT...)
        default {
            my $this_element = "ELE_$_";
            my $start_tag    = "S_$_";
            my $end_tag      = "E_$_";
            my $contents = $Marpa::UrHTML::Internal::CONTENTS{$_} // 'flow';
            push @rules,
                {
                lhs            => "$this_element",
                rhs            => ["T_$this_element"],
                action         => "!T_ELE_$_",
                },
                {
                lhs            => "$this_element",
                rhs            => ["U_$this_element"],
                action         => "!U_ELE_$_",
                },
                {
                lhs => "T_$this_element",
                rhs => [ $start_tag, $contents, $end_tag ],
                },
                {
                lhs => "U_$this_element",
                rhs => [$start_tag],
                };
            my $element_type =
                  $Marpa::UrHTML::Internal::HEAD_ELEMENT{$_} ? 'head_item'
                : $Marpa::UrHTML::Internal::BLOCK_ELEMENT{$_}
                ? 'block_element'
                : 'inline_element';
            push @rules,
                {
                lhs    => $element_type,
                rhs    => [$this_element],
                action => "!ELE_$_",
                };

            # There may be no
            # end tag in the input.
            # This silences the warning.
            if ( not $terminals{$end_tag} ) {
                push @terminals, $end_tag;
                $terminals{$end_tag}++;
            }

            $pseudo_class_element_actions{"!U_ELE_$_"} =
                [ UNTERMINATED => $_ ];
            $pseudo_class_element_actions{"!T_ELE_$_"} = [ TERMINATED => $_ ];
            $element_actions{"!ELE_$_"} = $_;
        } ## end default
    } ## end for ( keys %start_tags )

    my $grammar = Marpa::Grammar->new(
        {   rules          => \@rules,
            start          => 'document',
            terminals      => \@terminals,
            default_action => (
                $self->{user_handlers_by_pseudo_class}->{ANY}->{DEFAULT}
                    // 'Marpa::UrHTML::Internal::default_action'
            ),
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
        say "newly created recce size: ", total_size($recce);
    }

    $self->{recce}  = $recce;
    $self->{tokens} = \@html_parser_tokens;
    my ( $current_earleme, $expected_terminals ) = $recce->status();
    MARPA_TOKEN: for my $marpa_token (@marpa_tokens) {
        my $is_virtual_token = 1;
        VIRTUAL_TOKEN: while ($is_virtual_token) {
            my $token_to_add;
            FIND_VIRTUAL_TOKEN: {
                if ( $marpa_token->[0] ~~ $expected_terminals ) {
                    $token_to_add     = $marpa_token;
                    $is_virtual_token = 0;
                    last FIND_VIRTUAL_TOKEN;
                }
                my @optionals_expected =
                    grep { $Marpa::UrHTML::Internal::OPTIONAL_TERMINALS{$_} }
                    @{$expected_terminals};
                if ($trace_terminals) {
                    say {$trace_fh} "Converting Token: ", $marpa_token->[0];
                    say {$trace_fh} +( scalar @optionals_expected ),
                        " optionals expected: ", join " ",
                        @optionals_expected;
                } ## end if ($trace_terminals)
                if (defined(
                        my $optional_terminal = pop @optionals_expected
                    )
                    )
                {
                    my $tdesc_list = $marpa_token->[1];
                    my $first_tdesc_start_token =
                        $tdesc_list->[0]
                        ->[Marpa::UrHTML::Internal::TDesc::START_TOKEN];
                    $token_to_add = [
                        $optional_terminal,
                        [ [ 'EMPTY', $first_tdesc_start_token ] ]
                    ];
                    last FIND_VIRTUAL_TOKEN;
                } ## end if ( defined( my $optional_terminal = pop ...))

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
                        ${ tdesc_list_to_text( $self, $marpa_token->[1] ) },
                        q{"};
                } ## end if ($trace_cruft)
            } ## end FIND_VIRTUAL_TOKEN:
            ( $current_earleme, $expected_terminals ) =
                $recce->tokens( [$token_to_add], 'predict' );
            if ( not defined $current_earleme ) {
                my $last_marpa_token = $recce->furthest();
                $last_marpa_token =
                      $last_marpa_token > $#marpa_tokens
                    ? $#marpa_tokens
                    : $last_marpa_token;
                my ($furthest_offset, $furthest_offset_line) =
                    Marpa::UrHTML::Internal::earleme_to_offset( $self,
                    $last_marpa_token );
                say Data::Dumper::Dumper( $recce->find_parse() );
                Marpa::exception( "HTML parse exhausted at location $furthest_offset, line $furthest_offset_line" );
            } ## end if ( not defined $current_earleme )
        } ## end while ($is_virtual_token)
    } ## end for my $marpa_token (@marpa_tokens)

    if ($trace_terminals) {
        say {$trace_fh} "at end of tokens, expecting: ", join " ",
            @{$expected_terminals};
    }

    if ( $ENV{TRACE_SIZE} ) {
        say "pre-strip recce size: ", total_size($recce);
        for my $ix ( 0 .. $#{$recce} ) {
            say "pre-strip recce size, element $ix: ",
                total_size( $recce->[$ix] );
        }
    } ## end if ( $ENV{TRACE_SIZE} )
    $recce->strip();    # Saves lots of memory

    if ( $ENV{TRACE_SIZE} ) {
        say "post-strip recce size: ", total_size($recce);
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
        )
    );

    PSEUDO_CLASS:
    for my $pseudo_class (
        qw(PROLOG ROOT HEAD BODY TRAILER TERMINATED UNTERMINATED CRUFT))
    {
        my $pseudo_class_action =
            $self->{user_handlers_by_pseudo_class}->{ANY}->{$pseudo_class};
        my $pseudo_class_action_name = "!$pseudo_class" . '_handler';
        if ($pseudo_class_action) {
            $closure{$pseudo_class_action_name} =
                wrap_user_tdesc_handler($pseudo_class_action);
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
        my ( $pseudo_class, $element ) = @{$data};
        my $pseudo_class_action =
            $self->{user_handlers_by_pseudo_class}->{$element}
            ->{$pseudo_class}
            // $self->{user_handlers_by_pseudo_class}->{ANY}->{$pseudo_class};
        if ( defined $pseudo_class_action ) {
            $pseudo_class_action =
                wrap_user_tdesc_handler($pseudo_class_action);
        }
        $pseudo_class_action //= \&Marpa::UrHTML::Internal::default_action;
        $closure{$element_action} = $pseudo_class_action;
    } ## end while ( my ( $element_action, $data ) = each ...)

    my $value = do {
        local $Marpa::UrHTML::Internal::PARSE_INSTANCE = $self;
        local $Marpa::UrHTML::INSTANCE                 = {};
        my $evaler = Marpa::Evaluator->new(
            { recce => $recce, clone => 0, closures => \%closure, } );

        Marpa::exception('No parse') if not $evaler;

        if ( $ENV{TRACE_SIZE} ) {
            say "pre-undef recce size: ", total_size($recce);
            for my $ix ( 0 .. $#{$recce} ) {
                say "pre-undef recce size, element $ix: ",
                    total_size( $recce->[$ix] );
            }
        } ## end if ( $ENV{TRACE_SIZE} )

        $recce = undef;    # conserve memory

        if ( $ENV{TRACE_SIZE} ) {
            say "post-undef recce size: ", total_size($recce);
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
            say 'last good at ',
                substr( ${$document}, $last_good_offset, 100 );

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

=head1 DESCRIPTION

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
