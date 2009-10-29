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

=begin Implementation:

The HTML grammar is adapted from <!DOCTYPE HTML PUBLIC "-//W3C//DTD
HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
An effort is made to preserve naming and capitalization of the DTD,
while minimizing the use of special characters.

=end Implementation:

=cut

@Marpa::UrHTML::Internal::ELEMENTS = qw(
    A ABBR ACRONYM ADDRESS APPLET AREA B BASE BASEFONT BDO BIG BLOCKQUOTE
    BODY BR BUTTON CAPTION CENTER CITE CODE COL COLGROUP DD DEL DFN DIR
    DIV DL DT EM FIELDSET FONT FORM FRAME FRAMESET H1 H2 H3 H4 H5 H6 HEAD
    HR HTML I IFRAME IMG INPUT INS ISINDEX KBD LABEL LEGEND LI LINK MAP
    MENU META NOFRAMES NOSCRIPT OBJECT OL OPTGROUP OPTION P PARAM PRE
    Q S SAMP SCRIPT SELECT SMALL SPAN STRIKE STRONG STYLE SUB SUP TABLE
    TBODY TD TEXTAREA TFOOT TH THEAD TITLE TR TT U UL VAR
);


%Marpa::UrHTML::Internal::ELEMENTS_CONTAINING_CDATA =
    map { $_, 1 } qw( script style );
%Marpa::UrHTML::Internal::EMPTY_ELEMENTS = map { $_, 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param
);

%Marpa::UrHTML::Internal::ELEMENTS_WITH_BOTH_TAGS_OPTIONAL =
    map { $_, 1 } qw( html head body tbody );
%Marpa::UrHTML::Internal::ELEMENTS_WITH_OPTIONAL_END_TAG = map { $_, 1 }
    qw(
    html head body tbody
    area base basefont br col colgroup dd dt frame hr img input isindex
    li link meta option p param td tfoot th thead tr
);

@Marpa::UrHTML::Internal::RULES     = ();
@Marpa::UrHTML::Internal::TERMINALS = ();

$Marpa::UrHTML::Internal::MARPA_GRAMMAR_OPTIONS = {
    rules => \@Marpa::UrHTML::Internal::RULES,
    start => 'HTML',
    terminals => \@Marpa::UrHTML::Internal::TERMINALS,
};

my %elements = ();

sub Marpa::UrHTML::evaluate {
    my ($self) = @_;
    my $pull_parser = $self->{pull_parser};
    my @tokens = ();
    while ( my $token = $pull_parser->get_token ) {
        given ( shift @{$token} ) {
            when ('T') {
                my ( $offset, $offset_end, $text, $is_cdata ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                push @tokens, [ ( $is_cdata ? 'CDATA' : 'PCDATA' ), $text ];
            }
            when ('S') {
                my ( $offset, $offset_end, $tag_name, $attr, $attrseq, $text )
                    = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                $elements{$tag_name}++;
                my $terminal = $_ . q{_} . $tag_name;
                push @tokens, [ $terminal, $text ];
            } ## end when ('S')
            when ('E') {
                my ( $offset, $offset_end, $tag_name, $text ) = @{$token};
                say STDERR "$_ $offset $offset_end $text";
                $elements{$tag_name}++;
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
