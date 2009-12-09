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

my $codepoints = Storable::fd_retrieve(\*STDIN);

binmode STDOUT, ':utf8';

my @sort_data;
for my $key (keys %{$codepoints}) {
    my $codepoint_data = $codepoints->{$key};
    my $occurrence_count = $codepoint_data->{occurrence_count};
    (my $kangxi_text = $codepoint_data->{krskangxi}) =~ s/<[^<>]*>//xmsg;
    my ($radical, $strokes) = $kangxi_text =~ /(\d+)[.](\d+)/xms;
    my $sort_key = pack 'N*', 0x7FFFFFFF - $occurrence_count, $radical, $strokes;
    push @sort_data, [ $sort_key, $key ];
}

my @sorted_codepoints = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @sort_data;

my @long_fields = qw(
    occurrences
    shrift_occurrences
    shrift_notes
    cedict_definition
    unihan_definition
    ktang
);

print <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
<HEAD>
<TITLE>Glossary</TITLE>
<META http-equiv="Content-Type" content="text/html; charset=utf-8" />
<STYLE type="text/css">
   .title { border-width: 1; border: solid; text-align: center}
   .content {white-space: pre-wrap; }
   .inline_chinese { font-size:200%; line-height:150% }
   .subsection_label { font-weight:bold }
   .glyph { float: left; vertical-align: text-top; font-size: 400%; margin-right: 1.5em }
   .codepoint { margin-bottom: 3ex; margin-top: 3ex }
   .unicode_value { font-weight: bold; }
   .codepoint_datum_label { font-weight: bold }
</STYLE>
</HEAD>
<BODY>
EOF

for my $codepoint (@sorted_codepoints) {
    say qq{<div class="codepoint" title="$codepoint">};
    say qq{<table>};
    say qq{<td>};
    say $codepoints->{$codepoint}->{glyph};
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( unicode_value krskangxi krsunicode )) {
        if ( my $text = $codepoints->{$codepoint}->{$field} ) {
            say $text;
        }
    }
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( kfrequency kgradelevel ktotalstrokes)) {
        if ( my $text = $codepoints->{$codepoint}->{$field} ) {
            say $text;
        }
    }
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( kiicore kmandarin kmatthews)) {
        if ( my $text = $codepoints->{$codepoint}->{$field} ) {
            say $text;
        }
    }
    say qq{</td>};
    say qq{</table>};
    for my $field (@long_fields) {
        if ( my $text = $codepoints->{$codepoint}->{$field} ) {
            say $text;
        }
    }
    say qq{</div>};
} ## end for my $codepoint (@sorted_codepoints)

say '</BODY>';
say '</HTML>';
