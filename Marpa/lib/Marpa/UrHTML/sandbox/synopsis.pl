#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::UrHTML;
# use HTML::Tagset;
use List::Util;
use Test::More tests => 2;

BEGIN {
    use_ok('Marpa::UrHTML');
}

# Possible to do:
#
# Delete spacer tag (only implemented in Netscape prior to 6.0)
# Delete everything but title
# Delete PI's
# Delete everything but PI's
# Print links
# Print title
# Complexity measure (or approximation?)

# From notes:
#
# 'delete_me' class
# 'keep_me' class
# copy (no args)

my $example1 = '<?pi><table><?pi><tr><td><table><?pi>x</table></table><?pi>';
my $example2 = 'I am body text<head attr="I am cruft">I am more body text';
my $example3 = q{<p>I say<q>hello</q>I don't know why you say<q>goodbye</q></p>};

{
    my $expected = $example1;
    my $result   = Marpa::UrHTML->new()->parse( \$example1 );
    Test::More::is( ${$result}, $expected, 'no args is a straight copy' );
}

exit 0;


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
        : qq{\n<!-- Missing start tag for $tagname element -->\n}
    ) . Marpa::UrHTML::literal();
    !Marpa::UrHTML::end_tag() and $literal .= qq{\n<!-- Missing end tag for $tagname element -->\n};
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
                    ( my $commented_out = Marpa::UrHTML::literal() )
                        =~ s/--/- -/gxms;
                    return qq{\n<!-- removed pi: "$commented_out" -->\n};
                },
            ],
            [ table => sub { return Marpa::UrHTML::literal() }, ],
            [   ':TOP' => sub {

                            say STDERR Data::Dumper::Dumper(Marpa::UrHTML::child_data( 'pseudoclass,literal,original'));

                    return join q{},
                        map { ( $_->[0] // q{} ) eq 'PI' ? $_->[2] : $_->[1] }
                            @{
                            Marpa::UrHTML::child_data(
                                'pseudoclass,literal,original')
                            };
                    }
            ],
        ],
    }
)->parse( \$example1 );
say "Remove Processing Instructions only inside tables:\n", $value;

$value = Marpa::UrHTML->new(
    {   handlers => [
            [   'table' => sub {
                    my $table_depth = List::Util::max(
                        map { ${$_} } grep { ref $_ }
                            map { $_->[0] }
                            @{ Marpa::UrHTML::child_data('value') }
                    ) // 0;
                    return \( ++$table_depth );
                },
            ],
            [   ':TOP' => sub {
                    my $table_depth = List::Util::max(
                        map { ${$_} } grep { ref $_ }
                            map { $_->[0] }
                            @{ Marpa::UrHTML::child_data('value') }
                    ) // 0;
                    return "Maximum table depth = $table_depth";
                },
            ],
        ],
    }
)->parse( \$example1 );
say $value;
