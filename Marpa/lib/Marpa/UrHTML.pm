package Marpa::UrHTML;

use 5.010;
use strict;
use warnings;

use Carp ();
use English qw( -no_match_vars ) ;

use HTML::PullParser;
use HTML::Entities qw(decode_entities);
use HTML::Tagset ();
use Marpa;

package Marpa::UrHTML::Internal;

my %ARGS =
(
 start       => "'S',offset,offset_end,tagname,attr,attrseq,text",
 end         => "'E',offset,offset_end,tagname,text",
 text        => "'T',offset,offset_end,text,is_cdata",
 process     => "'PI',offset,offset_end,token0,text",
 comment     => "'C',offset,offset_end,text",
 declaration => "'D',offset,offset_end,text",

 # options that default on
 unbroken_text => 1,
);

sub Marpa::UrHTML::new
{
    my $class = shift;
    my $self = bless {}, $class;

    my %cnf;
    if (@_ == 1) {
        Carp::croak('Document is not ref to string')
            if ref $_[0] ne 'SCALAR';
	%cnf = (doc => $_[0]);
    }
    else {
	%cnf = @_;
    }

    my $textify = delete $cnf{textify} || {img => "alt", applet => "alt"};

    $self->{pull_parser} = HTML::PullParser->new( %cnf, %ARGS )
        || Carp::croak("Could not create pull parser");

    $self->{textify} = $textify;
    $self;
}

sub default_action {
    shift;
    return join q{}, @_;
}

%Marpa::UrHTML::Internal::EMPTY_ELEMENTS = map { $_, 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param
);

%Marpa::UrHTML::Internal::OPTIONAL_ELEMENT =
    map { $_, 1 } qw( html head body tbody );
%Marpa::UrHTML::Internal::OPTIONAL_END_TAG = map { $_, 1 }
    qw(
    area base basefont br col colgroup dd dt frame hr img input isindex
    li link meta option p param td tfoot th thead tr
);

@Marpa::UrHTML::Internal::CORE_TERMINALS = (
    map { ('S_' . $_), ('E' . $_) } (
        keys %Marpa::UrHTML::Internal::OPTIONAL_ELEMENT,
        keys %Marpa::UrHTML::Internal::OPTIONAL_END_TAG,
        key %Marpa::UrHTML::Internal::OPTIONAL_END_TAG
    )
);
%Marpa::UrHTML::Internal::CORE_TERMINALS = map { $_ => 1 } 
    @Marpa::UrHTML::Internal::CORE_TERMINALS;

# Create ELE_x ::= S_x rules for the empty elements?
@Marpa::UrHTML::Internal::CORE_RULES = (
    map {
        { $lhs     => 'ignored_html_markup', { rhs => [ 'S_' . $_ ] } },
            { $lhs => 'ignored_html_markup', { rhs => [ 'E_' . $_ ] } }
        } keys %Marpa::UrHTML::Internal::OPTIONAL_ELEMENT
    ),
    (
    map {
        { $lhs => 'ignored_html_markup', { rhs => [ 'E_' . $_ ] } }
        } keys %Marpa::UrHTML::Internal::OPTIONAL_END_TAG
    ),
    ;

Marpa::UrHTML::Internal::MARPA_GRAMMAR_OPTIONS = {
    rules => \@Marpa::UrHTML::Internal::RULES,
    start => 'HTML',
    terminals => \@Marpa::UrHTML::Internal::TERMINALS,
};

my %start_tags = ();
my %end_tags = ();

sub Marpa::UrHTML::evaluate {
    my ($self) = @_;
    my $pull_parser = $self->{pull_parser};
    my @tokens = ();
    while ( my $token = $pull_parser->get_token ) {
        given ( shift @{$token} ) {
            when ('T') {
                my ( $offset, $offset_end, $text, $is_cdata ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
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
                say STDERR "$_ $offset $offset_end $text";
                $start_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                push @tokens, [ $terminal, $text ];
            } ## end when ('S')
            when ('E') {
                my ( $offset, $offset_end, $tag_name, $text ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                $end_tags{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                push @tokens, [ $terminal, $text ];
            } ## end when ('E')
            when ( [qw(C D)] ) {
                my ( $offset, $offset_end, $text ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                push @tokens, [ $_, $text ];
            }
            when ( ['PI'] ) {
                my ( $offset, $offset_end, $token0, $text ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                push @tokens, [ $_, $text ];
            }
            default { Carp::croak("Unprovided-for event: $_") }
        } ## end given
    } ## end while ( my $token = $self->get_token )

    my @rules = @Marpa::UrHTML::Internal::CORE_RULES;

    ELEMENT: for my $element (keys %start_tags) {
        # For some elements the default rule making does not apply
        next ELEMENT if $Marpa::UrHTML::Internal::SPECIAL_ELEMENT{$element};
        push @rules,
            { $lhs => "ELE_$element", rhs => [ "S_$element", "Contents_$element", "E_$element" ] }
            { $lhs => "UELE_$element", rhs => [ "S_$element", "Contents_$element" ] }
            { $lhs => "Contents_$element", rhs => [ "S_$element", "Contents_$element" ] }
            ;
    }

    # my $grammar = Marpa::Grammar->new( $Marpa::UrHTML::Internal::MARPA_GRAMMAR_OPTIONS );

    return \@tokens;

} ## end sub value

sub get_tag
{
    my $self = shift;
    my $token;
    while (1) {
	$token = $self->get_token || return undef;
	my $type = shift @$token;
	next unless $type eq "S" || $type eq "E";
	substr($token->[0], 0, 0) = "/" if $type eq "E";
	return $token unless @_;
	for (@_) {
	    return $token if $token->[0] eq $_;
	}
    }
}

sub _textify {
    my($self, $token) = @_;
    my $tag = $token->[1];
    return undef unless exists $self->{textify}{$tag};

    my $alt = $self->{textify}{$tag};
    my $text;
    if (ref($alt)) {
	$text = &$alt(@$token);
    } else {
	$text = $token->[2]{$alt || "alt"};
	$text = "[\U$tag]" unless defined $text;
    }
    return $text;
}


sub get_text
{
    my $self = shift;
    my @text;
    while (my $token = $self->get_token) {
	my $type = $token->[0];
	if ($type eq "T") {
	    my $text = $token->[1];
	    decode_entities($text) unless $token->[2];
	    push(@text, $text);
	} elsif ($type =~ /^[SE]$/) {
	    my $tag = $token->[1];
	    if ($type eq "S") {
		if (defined(my $text = _textify($self, $token))) {
		    push(@text, $text);
		    next;
		}
	    } else {
		$tag = "/$tag";
	    }
	    if (!@_ || grep $_ eq $tag, @_) {
		 $self->unget_token($token);
		 last;
	    }
	    push(@text, " ")
		if $tag eq "br" || !$HTML::Tagset::isPhraseMarkup{$token->[1]};
	}
    }
    join("", @text);
}


sub get_trimmed_text
{
    my $self = shift;
    my $text = $self->get_text(@_);
    $text =~ s/^\s+//; $text =~ s/\s+$//; $text =~ s/\s+/ /g;
    $text;
}

sub get_phrase {
    my $self = shift;
    my @text;
    while (my $token = $self->get_token) {
	my $type = $token->[0];
	if ($type eq "T") {
	    my $text = $token->[1];
	    decode_entities($text) unless $token->[2];
	    push(@text, $text);
	} elsif ($type =~ /^[SE]$/) {
	    my $tag = $token->[1];
	    if ($type eq "S") {
		if (defined(my $text = _textify($self, $token))) {
		    push(@text, $text);
		    next;
		}
	    }
	    if (!$HTML::Tagset::isPhraseMarkup{$tag}) {
		$self->unget_token($token);
		last;
	    }
	    push(@text, " ") if $tag eq "br";
	}
    }
    my $text = join("", @text);
    $text =~ s/^\s+//; $text =~ s/\s+$//; $text =~ s/\s+/ /g;
    $text;
}

1;

__END__

=head1 NAME

Marpa::Ur_HTML - Element-level HTML Parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

This is a rewrite of HTML::TokeParser, which was written by Gisle Aas.

=head1 COPYRIGHT

Copyright 1998-2005 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
