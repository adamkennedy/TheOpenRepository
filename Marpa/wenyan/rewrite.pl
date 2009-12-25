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
use Storable;

use Marpa::UrHTML;

binmode STDIN, ':utf8';
binmode STDERR, ':utf8';

my $document = do { local $RS = undef; \(<STDIN>) };

my %handlers = (
    ':TOP' => sub {
        return $Marpa::UrHTML::INSTANCE;
    },
    '.codepoint' => sub {
        for my $value ( @{ &Marpa::UrHTML::descendant_values() } ) {
            next CHILD if not $value;
            my ( $class, $literal, $data ) = @{$value};
            if ( $class eq 'occurrences' ) {
                $Marpa::UrHTML::INSTANCE->{ Marpa::UrHTML::title() }
                    ->{occurrence_count} = $data;
            }
            $Marpa::UrHTML::INSTANCE->{ Marpa::UrHTML::title() }->{$class} =
                $literal;
        } ## end for my $value ( @{ &Marpa::UrHTML::descendant_values(...)})
        return;
    },
    'div' => sub {
        my $class = Marpa::UrHTML::attributes()->{class};
        Carp::croak(qq{WARNING: Unknown class for div: "$class"});
    },
);

$handlers{'.occurrences'} = sub {
    my $literal = Marpa::UrHTML::literal();
    my ($occurrence_count) =
        ( $literal =~ / Occurrences \s+ [(] (\d+) [)] [:] /xms );
    return [ 'occurrences', $literal, $occurrence_count ];
};

my @short_text_fields;
my @long_text_fields;

my @text_fields = qw( cedict_definition glyph kfrequency kgradelevel
    kiicore kmandarin kmatthews krskangxi
    krsunicode ktang ktotalstrokes shrift_notes
    shrift_occurrences unicode_value unihan_definition );

for my $class (@text_fields) {
    $handlers{".$class"} = sub { return [ $class, Marpa::UrHTML::literal() ] }
}

my $codepoint_hash = Marpa::UrHTML::urhtml( $document, \%handlers );

Storable::store_fd $codepoint_hash, \*STDOUT;

__END__
