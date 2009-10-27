#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use YAML::XS;
use English qw( -no_match_vars );
use Carp;
use Fatal qw(open);
use List::Util;

my $project_dir = $ENV{WENYAN_PROJECT_DIR};
Carp::croak('WENYAN_PROJECT_DIR not set') if not defined $project_dir;
Carp::croak("$project_dir not found") if not -d $project_dir;

binmode(STDOUT, ':utf8');

# use Smart::Comments;

### <where> ...

my $cedict_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/characters/cedict.yml";
    YAML::XS::Load(<$fh>);
};
my $unihan_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/characters/unihan.yml";
    YAML::XS::Load(<$fh>);
};
my $zi_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/characters/zi_character.yml";
    YAML::XS::Load(<$fh>);
};
my $notes_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/translate/notes.yml";
    YAML::XS::Load(<$fh>);
};
my $shrift_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/translate/shrift.yml";
    YAML::XS::Load(<$fh>);
};
my $unicode_db = do {
    $RS = undef;
    open my $fh, '<', "$project_dir/characters/unicode.yml";
    YAML::XS::Load(<$fh>);
};

my %mathews_by_unicode = ();
while (my ($mathews, $unicode) = each %{$unicode_db}) {
    Carp::croak("Mathews already defined for unicode: $unicode")
        if defined $mathews_by_unicode{$unicode};
    $mathews_by_unicode{$unicode} = $mathews;
}

my %occurrences;
my %ideograph;
TAG: for my $tag (keys %{$zi_db}) {
    next TAG if $tag !~ / ^ \d+[.][0-7] [x]? /xms;
    my $tag_data = $zi_db->{$tag};
    CHAR: for my $char_ix ( 0 .. $#{$tag_data} ) {
        my $char_data  = $tag_data->[$char_ix];
        my $mathews   = $char_data->{matthews};
        push @{$occurrences{$mathews}}, "$tag:$char_ix";
        my $unicode = $unicode_db->{$mathews};
        $ideograph{$unicode}++;
    }
}

my %shrift_occurrences;
TAG: for my $tag (keys %{$shrift_db}) {
    next TAG if $tag !~ / ^ \d+[.][0-7] [x]? /xms;
    my $tag_data = $shrift_db->{$tag};
    CHAR: for my $char_ix ( 0 .. $#{$tag_data} ) {
        my $char_data  = $tag_data->[$char_ix];
        my ($char_key, $meaning) = %{$char_data};
        next CHAR if $meaning =~ / \A [?] /xms;
        push @{$shrift_occurrences{$char_key}}, "$tag: $meaning";
    }
}

my %output = ();
my %glyph = ();
CHAR: for my $unicode ( keys %ideograph ) {
    my $mathews   = $mathews_by_unicode{$unicode};

    my $glyph = hex(substr($unicode, 2));
    my $kRSKangXi = $unihan_db->{$unicode}{kRSKangXi};
    my $sort_key = do {
        my ($radical, $residual) = split /[.]/, $kRSKangXi;
        sprintf '%03d%02d%04x', $radical, $residual, $glyph;
    };
    $glyph{$sort_key} = sprintf '%c', $glyph;
    push @{ $output{$sort_key} },
        [ 'unicode_value',  '',   $unicode ],
        [ 'kMandarin',  'Mandarin',   lc $unihan_db->{$unicode}{kMandarin} ],
        [ 'kMatthews',  'Mathews',    $unihan_db->{$unicode}{kMatthews} ],
        [ 'kRSKangXi',  'Kang Xi RS', $unihan_db->{$unicode}{kRSKangXi} ],
        [ 'kRSUnicode', 'Unicode RS', $unihan_db->{$unicode}{kRSUnicode} ],
        [ 'kTotalStrokes', 'Total Strokes', $unihan_db->{$unicode}{kTotalStrokes} ],
        [ 'kFrequency', 'Frequency', $unihan_db->{$unicode}{kFrequency} ],
        [ 'kGradeLevel', 'Grade Level', $unihan_db->{$unicode}{kGradeLevel} ],
        [ 'shrift_notes', 'Notes', $notes_db->{$mathews} ],
        [
        'cedict_definition', 'CEDICT Definition',
        $cedict_db->{$unicode}{definition}
        ],
        [
        'unihan_definition', 'Unihan Definition',
        $unihan_db->{$unicode}{kDefinition}
        ];

    my $shrift_list = $shrift_occurrences{$mathews};
    if ($shrift_list) {
        my $shrift_occurrence_count = scalar @{$shrift_list};
        my $shrift_occurrence_description =
            "Shrift Occurrences ($shrift_occurrence_count): "
                . (
                join "; ",
                (   sort @{$shrift_list}[
                        0 .. List::Util::min( $shrift_occurrence_count - 1,
                            40 )
                    ]
                )
                );
        push @{ $output{$sort_key} },
            [
            'shrift_occurrences', 'Shrift Occurrences',
            $shrift_occurrence_description
            ];
    } ## end if ($shrift_list)

    my $char_occurrences = $occurrences{$mathews};
    my $occurrence_count = scalar @{$char_occurrences};
    my $occurrence_description =
        "Occurrences ($occurrence_count): "
            . (
            join ", ",
            (   sort @{$char_occurrences}
                    [ 0 .. List::Util::min( $occurrence_count - 1, 40 ) ]
            )
            );
    push @{ $output{$sort_key} },
        [
        'occurrences', 'Occurrences',
        $occurrence_description
        ];

    push @{$output{$sort_key}},
        [ 'kIICore', 'IICore', $unihan_db->{$unicode}{kIICore} ],
        [ 'kTang', 'Tang Pronunciation', $unihan_db->{$unicode}{kTang} ],
        ;

} ## end for my $char_ix ( 0 .. $#{$tag_data} )

for my $sort_key (sort keys %output) {
    my $codepoint_data = $output{$sort_key};
    my $glyph = $glyph{$sort_key};
    say q{<div class="codepoint" title="U+}, (sprintf '%04x', ord($glyph)), q{">};
    say '<div class="glyph">', $glyph, '</div>';
    DATUM: for my $codepoint_datum (@{$codepoint_data}) {
        # say STDERR Dumper($codepoint_datum);
        my ($class, $label, $value) = @{$codepoint_datum};
        next DATUM if not defined $value;
        say '<div class="', $class, '">';
        if ($label) {
            say qq{<span class="codepoint_datum_label">$label</span>:};
        }
        say $value;
        say '</div>';
    }
    say q{</div>};
}
