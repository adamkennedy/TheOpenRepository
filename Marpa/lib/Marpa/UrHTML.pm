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

package Marpa::UrHTML::Internal;

use Marpa::Internal;

my %ARGS = (
    start       => q{'S',offset,offset_end,tagname,attr,attrseq,text},
    end         => q{'E',offset,offset_end,tagname,text},
    text        => q{'T',offset,offset_end,text,is_cdata},
    process     => q{'PI',offset,offset_end,token0,text},
    comment     => q{'C',offset,offset_end,text},
    declaration => q{'D',offset,offset_end,text},

    # options that default on
    unbroken_text => 1,
);

## no critic (Subroutines::RequireArgUnpacking)
sub Marpa::UrHTML::new {
    my $class = shift;
    my $self = bless {}, $class;

    my %cnf;
    if ( @_ == 1 ) {
        Carp::croak('Document is not ref to string')
            if ref $_[0] ne 'SCALAR';
        %cnf = ( doc => $_[0] );
    }
    else {
        %cnf = @_;
    }

    my $textify = delete $cnf{textify} || { img => 'alt', applet => 'alt' };

    $self->{pull_parser} = HTML::PullParser->new( %cnf, %ARGS )
        || Carp::croak('Could not create pull parser');

    $self->{textify} = $textify;
    return $self;
} ## end sub Marpa::UrHTML::new
## use critic

## no critic (Subroutines::RequireArgUnpacking)
sub default_action {
    shift;
    return join q{}, @_;
}
## use critic

%Marpa::UrHTML::Internal::BLOCK_ELEMENT = map { $_ => 1 } qw(
    h1 h2 h3 h4 h5 h6
    ul ol dir menu
    pre
    p dl div center
    noscript noframes
    blockquote form isindex hr
    table fieldset address
);

%Marpa::UrHTML::Internal::EMPTY_ELEMENT = map { $_ => 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param
);

%Marpa::UrHTML::Internal::OPTIONAL_TAGS =
    map { ( $_, 1 ) } qw( html head body tbody );
%Marpa::UrHTML::Internal::OPTIONAL_END_TAG = map { $_ => 1 } qw(
    colgroup dd dt li p td tfoot th thead tr
);

my @anywhere_rh_sides = qw(D C PI WHITESPACE);

# Start and end of optional-tag elements is simply
# ignored
push @anywhere_rh_sides, map { ( 'S_' . $_, 'E_' . $_ ) }
    keys %Marpa::UrHTML::Internal::OPTIONAL_TAGS;

@Marpa::UrHTML::Internal::CORE_TERMINALS =
    ( @anywhere_rh_sides, qw(CDATA PCDATA) );

# End tags for empty elements are ignored
push @anywhere_rh_sides,
    map { 'E_' . $_ } keys %Marpa::UrHTML::Internal::EMPTY_ELEMENTS;

my @anywhere_item_rules =
    map { { lhs => 'anywhere_item', rhs => [$_] } } @anywhere_rh_sides;

@Marpa::UrHTML::Internal::CORE_RULES = (
    @anywhere_item_rules,
    { lhs => 'document', rhs => ['flow'] },
    { lhs => 'flow',     rhs => ['terminated_flow_item'], },
    # { lhs => 'flow',     rhs => ['U_ELE_p'], },
    { lhs => 'flow',     rhs => [qw(flow terminated_flow_item)], },
    # {   lhs => 'flow',
        # rhs => [qw(U_ELE_p block_terminating_flow)],
    # },
    # { lhs => 'block_terminating_flow', rhs => ['block_element'], },
    # { lhs => 'block_terminating_flow', rhs => [ 'block_element', 'flow' ], },
    # { lhs => 'inline_flow',            rhs => ['inline_flow_item'], },
    # { lhs => 'inline_flow',   rhs => [qw(inline_flow_item inline_flow)], },
    # { lhs => 'block_element', rhs => ['ELE_p'] },
    # { lhs => 'ELE_p',         rhs => ['T_ELE_p'] },
    # { lhs => 'ELE_p',         rhs => ['U_ELE_p'] },
    # { lhs => 'T_ELE_p',       rhs => [ 'S_p', 'inline_flow', 'E_p' ] },
    # { lhs => 'U_ELE_p', rhs => [ 'S_p', 'inline_flow' ] },
);

# push @Marpa::UrHTML::Internal::CORE_TERMINALS, qw(S_p E_p );

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'terminated_flow_item', rhs => [$_] } }
    qw(inline_flow_item block_element);

push @Marpa::UrHTML::Internal::CORE_RULES,
    map { { lhs => 'inline_flow_item', rhs => [$_] } }
    qw(CDATA PCDATA anywhere_item anywhere_element);

my %start_tags = ();
my %end_tags   = ();

sub Marpa::UrHTML::evaluate {
    my ($self)      = @_;
    my $pull_parser = $self->{pull_parser};
    my @tokens      = ();

    my %terminals = map { $_ => 1 } @Marpa::UrHTML::Internal::CORE_TERMINALS;
    while ( my $token = $pull_parser->get_token ) {
        given ( shift @{$token} ) {
            when ('T') {
                my ( $offset, $offset_end, $text, $is_cdata ) = @{$token};
                # say "$_ $offset $offset_end $text";
                push @tokens,
                    [
                    (     $text =~ / \A \s* \z /xms ? 'WHITESPACE'
                        : $is_cdata ? 'CDATA'
                        : 'PCDATA'
                    ),
                    $text
                    ];
            } ## end when ('T')
            when ('S') {
                my ( $offset, $offset_end, $tag_name, $attr, $attrseq, $text )
                    = @{$token};
                # say "$_ $offset $offset_end $text";
                $start_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                $terminals{$terminal}++;
                push @tokens,
                    [ $terminal, $text ];
            } ## end when ('S')
            when ('E') {
                my ( $offset, $offset_end, $tag_name, $text ) = @{$token};
                # say "$_ $offset $offset_end $text";
                $end_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                $terminals{$terminal}++;
                push @tokens,
                    [ $terminal, $text ];
            } ## end when ('E')
            when ( [qw(C D)] ) {
                my ( $offset, $offset_end, $text ) = @{$token};
                # say "$_ $offset $offset_end $text";
                push @tokens,
                    [ $_, $text ];
            }
            when ( ['PI'] ) {
                my ( $offset, $offset_end, $token0, $text ) = @{$token};
                # say "$_ $offset $offset_end $text";
                push @tokens,
                    [ $_, $text ];
            }
            default { Carp::croak("Unprovided-for event: $_") }
        } ## end given
    } ## end while ( my $token = $pull_parser->get_token )

    my @rules = @Marpa::UrHTML::Internal::CORE_RULES;
    my @terminals = keys %terminals;

    ELEMENT: for ( keys %start_tags ) {
        when ( defined $Marpa::UrHTML::Internal::OPTIONAL_TAGS{$_} ) {

            # All these tags are simply ignored
            say "Ignored: Optional Tag: $_";

            # should be next ELEMENT, but perl bug 65114 causes warning if tag is given
            # next ELEMENT
            next;
        } ## end when ( defined $Marpa::UrHTML::Internal::OPTIONAL_TAGS...)
        when ( defined $Marpa::UrHTML::Internal::OPTIONAL_END_TAG{$_} ) {
            say "Optional End Tag: $_";

            # These will need custom solutions
            # A dummy rule for now
            push @rules,
                {
                lhs  => "ELE_$_",
                rhs => [ "S_$_", "Contents_$_", "E_$_" ]
                },
                {
                lhs => "UELE_$_",
                rhs => [ "S_$_", "Contents_$_" ]
                },

                # a rule which will never be satisfied because
                # there are no unicorns
                {
                lhs => "Contents_$_",
                rhs => [q{!!!unicorn!!!}]
                }
        } ## end when ( defined $Marpa::UrHTML::Internal::OPTIONAL_END_TAG...)
        when ( defined $Marpa::UrHTML::Internal::EMPTY_ELEMENT{$_} ) {
            say "Empty: $_";
            push @rules,
                {
                lhs => "ELE_$_",
                rhs => ["S_$_"]
                };
        } ## end when ( defined $Marpa::UrHTML::Internal::EMPTY_ELEMENT...)
        default {
            say "Standard: $_";
            my $this_element = "ELE_$_";
            push @rules,
                {
                lhs => $this_element,
                rhs => [ "S_$_", "Contents_$_", "E_$_" ]
                },
                {
                lhs => "Contents_$_",
                rhs => ['flow']
                };
            my $element_type =
                $Marpa::UrHTML::Internal::BLOCK_ELEMENT{$_}
                ? 'block_element'
                : 'anywhere_element';
            push @rules,
                {
                lhs => $element_type,
                rhs => [$this_element],
                };
        } ## end default
    } ## end for ( keys %start_tags )

    my $grammar = Marpa::Grammar->new( {
        rules     => \@rules,
        start     => 'document',
        terminals => \@terminals,
        strip => 0,
    });
    $grammar->precompute();
    say STDERR $grammar->show_rules();
    say STDERR $grammar->show_QDFA();
    my $recce = Marpa::Recognizer->new( { grammar=>$grammar } );
    say STDERR "token count: ", scalar @tokens;
    $recce->tokens( \@tokens );
    say STDERR $recce->show_earley_sets();

    return 1;

} ## end sub Marpa::UrHTML::evaluate

sub _textify {
    my ( $self, $token ) = @_;
    my $tag = $token->[1];
    return if not exists $self->{textify}{$tag};

    my $alt = $self->{textify}{$tag};
    my $text;
    if ( ref $alt ) {
        $text = &{$alt}( @{$token} );
    }
    else {
        $text = $token->[2]{ $alt || 'alt' };
        $text //= "[\U$tag]";
    }
    return $text;
} ## end sub _textify

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
