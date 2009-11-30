#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::UrHTML;
use HTML::Tagset;

my $example1 = '<?pi><table><?pi><tr><td><table><?pi>x</table></table><?pi>';
my $example2 = 'I am body text<head attr="I am cruft">I am more body text';

sub mark_cruft {
    my $literal = Marpa::UrHTML::literal();
    my ( $dummy, $line ) = Marpa::UrHTML::offset();
    return
          "\n<!-- "
        . ( length $literal )
        . " characters of cruft starting here -->"
        . $literal;
} ## end sub mark_cruft

sub mark_missing_tags {
    my $tagname = Marpa::UrHTML::tagname();
    return if $HTML::Tagset::emptyElement{$tagname};
    my $literal = (
        Marpa::UrHTML::start_tag()
        ? q{}
        : qq{\n<!-- Missing start tag for $tagname element -->}
    ) . Marpa::UrHTML::literal();
    if ( !Marpa::UrHTML::end_tag() ) {
        chomp $literal;
        $literal .= qq{\n<!-- Missing end tag for $tagname element -->};
    }
    return $literal;
} ## end sub mark_missing_tags

sub comment_out_pi {
    ( my $literal = Marpa::UrHTML::literal() ) =~ s/--/- -/g;
    return qq{\n<!-- removed pi: "$literal" -->\n};
}

my $format_args = { handlers => [ [ q{*} => \&mark_missing_tags ], ] };

my $value = Marpa::UrHTML->new($format_args)->parse(\$example1);
say "Mark Missing Tags:\n", ${$value};


$value = Marpa::UrHTML->new(
    {   handlers => [
            [ ':CRUFT' => \&mark_cruft ], [ q{*} => \&mark_missing_tags ],
        ]
    }
)->parse( \$example2 );
say "Mark Cruft:\n", ${$value};

$value =
    Marpa::UrHTML->new( { handlers => [ [ ':PI' => \&comment_out_pi ], ] } )
    ->parse( \$example1 );
say "Remove Processing Instructions:\n", ${$value};

$value = Marpa::UrHTML->new(
    {   handlers =>
            [ [ ':PI' => \&comment_out_pi ], [ table => sub {return} ], ]
    }
)->parse( \$example1 );
say "Remove Processing Instructions except inside table:\n", ${$value};

$value = Marpa::UrHTML->new(
    {   handlers => [
            [   ':PI' => sub {
                    my $original = Marpa::UrHTML::literal();
                    ( my $commented_out = $original ) =~ s/--/- -/gxms;
                    $commented_out =
                        qq{\n<!-- removed pi: "$commented_out" -->\n};
                    $Marpa::UrHTML::INSTANCE->{original_pi}
                        ->{$commented_out} = $original;
                    return $commented_out;
                },
            ],
            [   table => sub {
                    my $child_data = Marpa::UrHTML::child_data('literal');
                    return join q{},
                        map { $_->[0] } @{$child_data};
                },
            ],
            [   ':TOP' => sub {
                    return join q{}, map {
                        ( defined $_->[0] && $_->[0] eq 'PI' )
                            ? $Marpa::UrHTML::INSTANCE->{original_pi}
                            ->{ $_->[1] }
                            : $_->[1]
                        } @{ Marpa::UrHTML::child_data('pseudoclass,literal')
                        };
                },
            ],
        ],
    }
)->parse( \$example1 );
say "Remove Processing Instructions only inside tables, Solution 1:\n", $value;

$value = Marpa::UrHTML->new(
    {   handlers => [
            [   ':PI' => sub {
                    my $original = Marpa::UrHTML::literal();
                    ( my $commented_out = $original ) =~ s/--/- -/gxms;
                    $commented_out =
                        qq{\n<!-- removed pi: "$commented_out" -->\n};
                    return [ $original, $commented_out ];
                },
            ],
            [   table => sub {
                    my $child_data =
                        Marpa::UrHTML::child_data('value,literal');
                    return join q{}, map {
                             !defined $_->[0] ? $_->[1]
                            : ref $_->[0]     ? $_->[0]->[1]
                            : $_->[0]
                    } @{$child_data};
                },
            ],
            [   ':TOP' => sub {
                    my $child_data =
                        Marpa::UrHTML::child_data('value,literal');
                    return join q{}, map {
                             !defined $_->[0] ? $_->[1]
                            : ref $_->[0]     ? $_->[0]->[0]
                            : $_->[0]
                    } @{$child_data};
                },
            ],
        ],
    }
)->parse( \$example1 );
say "Remove Processing Instructions only inside table, Solution 2:\n", $value;
