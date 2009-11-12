#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Fatal qw(open close);

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open);

use Marpa::UrHTML;

my $document;
{
    local $RS = undef;
    $document = <STDIN>;
};

my @handlers = (
    [   'document' => sub {
        return $Marpa::UrHTML::INSTANCE;
    }
    ],
    [   '.codepoint' => sub {
            for my $value ( @{$Marpa::UrHTML::ELEMENT_VALUES} ) {
                next CHILD if not $value;
                say STDERR Data::Dumper->Dump([$value], ['value']);
                my ( $class, $literal, $data ) = @{ $value };
                if ($class eq 'occurrences') {
                    $Marpa::UrHTML::INSTANCE->{$Marpa::UrHTML::TITLE}->{occurrence_count} = $data;
                }
                $Marpa::UrHTML::INSTANCE->{$Marpa::UrHTML::TITLE}->{$class} = $literal;
            }
            return;
            }
    ]
);

push @handlers, 
       [   '.occurrences' =>
                sub {
                my $literal = $Marpa::UrHTML::LITERAL;
                my ($occurrence_count) = ($literal =~ / Occurrences \s+ [(] (\d+) [)] [:] /xms);
                return [ 'occurrences', $Marpa::UrHTML::LITERAL, $occurrence_count ]
                }
        ];

push @handlers, map {
    [ ".$_" => sub { return [ $_, $Marpa::UrHTML::LITERAL ] } ]
    } qw( cedict_definition glyph kfrequency kgradelevel
    kiicore kmandarin kmatthews krskangxi
    krsunicode ktang ktotalstrokes shrift_notes
    shrift_occurrences unicode_value unihan_definition );

my $p = Marpa::UrHTML->new( { handlers => \@handlers } );
my $value = $p->parse( \$document );

# Marpa::Test::is( ${ ${$value} }, $no_tang_document, 'remove kTang class' );

__END__
