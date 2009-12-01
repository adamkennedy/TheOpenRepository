#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::UrHTML;
use WWW::Mechanize;

my $uri = shift;
my $mech = WWW::Mechanize->new( autocheck => 1 );
$mech->get( $uri );
my $document = $mech->content;
undef $mech;

sub calculate_max_depths {
    my ($child_data) = @_;
    my %return_value = ();
    for my $child_value ( grep { ref $_ } map { $_->[0] } @{$child_data} ) {
        CHILD_TAGNAME: for my $child_tagname ( keys %{$child_value} ) {
            my $depth = $child_value->{$child_tagname};
            next CHILD_TAGNAME
                if $depth <= ( $return_value{$child_tagname} // 0 );
            $return_value{$child_tagname} = $depth;
        } ## end for my $child_tagname ( keys %{$child_value} )
    } ## end for my $child_value ( grep { ref $_ } map { $_->[0] }...)
    return \%return_value;
} ## end sub calculate_max_depths

my $value = Marpa::UrHTML->new(
    {   handlers => [
            [   q{*} => sub {
                    my $child_data = Marpa::UrHTML::child_data('value');
                    my $tagname    = Marpa::UrHTML::tagname();
                    $Marpa::UrHTML::INSTANCE->{count}->{$tagname}++;
                    $Marpa::UrHTML::INSTANCE->{length}->{$tagname} += (length Marpa::UrHTML::original());
                    my $return_value = calculate_max_depths($child_data);
                    ($return_value->{$tagname} //= 0)++;
                    return $return_value;
                },
            ],
            [   ':TOP' => sub {
                    my $child_data = Marpa::UrHTML::child_data('value');
                    my $result =
                        qq{<table cellpadding="3" border="1">}
                        . qq{<caption>$uri</caption>\n}
                        . qq{<thead><tr><th>Element<th>Depth<th>Number of<br>Elements}
                        . qq{<th>Size in<br>Characters</th>}
                        . qq{<th>Average<br>Size</th>}
                        . qq{</tr></thead>\n};
                    my $max_depths = calculate_max_depths($child_data);
                    for my $element ( sort keys %{$max_depths} ) {
                        my $count = $Marpa::UrHTML::INSTANCE->{count}->{$element};
                        my $size = $Marpa::UrHTML::INSTANCE->{length}->{$element};
                        $result .= join q{},
                            q{<tr>},
                            q{<td>}, $element, q{</td>},
                            q{<td align="right">}, $max_depths->{$element}, q{</td>},
                            q{<td align="right">}, $count, q{</td>},
                            q{<td align="right">}, $size, q{</td>},
                            q{<td align="right">}, int($size/$count), q{</td>},
                            "</tr>\n";
                    } ## end for my $element ( sort keys %{$max_depths} )
                    return $result . qq{</table>\n};
                },
            ],
        ],
    }
)->parse( \$document );

say $value;
