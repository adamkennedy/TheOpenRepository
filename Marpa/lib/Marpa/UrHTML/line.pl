#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Fatal qw(open close);
use Encode;

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open);
use Storable;

binmode STDOUT, ':utf8';

my %codepoint_in_text = ();
my @received_text = ();
RECEIVED_TEXT: while (my $line = <STDIN>) {
    chomp $line;
    last RECEIVED_TEXT if not $line;
    say STDERR $line;
    push @received_text, $line;
    $codepoint_in_text{lc $line}++;
}

my $received_text = join q{ }, map { sprintf '%c', hex(substr($_, 2)) } @received_text;

my @xiang_zhuan = ();
XIANG_ZHUAN: while (my $line = <STDIN>) {
    chomp $line;
    push @xiang_zhuan, $line;
    $codepoint_in_text{lc $line}++;
}

my $xiang_zhuan = join q{ }, map { sprintf '%c', hex(substr($_, 2)) } @xiang_zhuan;

my $codepoints = Storable::retrieve('wenyan.storable');

my @sorted_codepoints =
    map  { $_->[1] }
    sort { $b->[0] <=> $a->[0] }
    map  { [ $codepoints->{$_}->{occurrence_count}, $_ ] }
    keys %codepoint_in_text;

my @long_fields = qw(
occurrences
    shrift_occurrences
    shrift_notes
cedict_definition
    unihan_definition
    ktang
);

print <<'EOF';
<HTML>
<HEAD>
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

say qq{<div class="inline_chinese">};
say $received_text;
say qq{</div>};
say qq{<div class="inline_chinese">};
say $xiang_zhuan;
say qq{</div>};

for my $codepoint (@sorted_codepoints) {
    say qq{<div class="codepoint" title="$codepoint">};
    say qq{<table>};
    say qq{<td>};
    say ${ $codepoints->{$codepoint}->{glyph} };
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( unicode_value krskangxi krsunicode )) {
        if ( my $text_ref = $codepoints->{$codepoint}->{$field} ) {
            say ${$text_ref};
        }
    }
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( kfrequency kgradelevel ktotalstrokes)) {
        if ( my $text_ref = $codepoints->{$codepoint}->{$field} ) {
            say ${$text_ref};
        }
    }
    say qq{</td>};
    say qq{<td>};
    for my $field (qw( kiicore kmandarin kmatthews)) {
        if ( my $text_ref = $codepoints->{$codepoint}->{$field} ) {
            say ${$text_ref};
        }
    }
    say qq{</td>};
    say qq{</table>};
    for my $field (@long_fields) {
        if ( my $text_ref = $codepoints->{$codepoint}->{$field} ) {
            say ${$text_ref};
        }
    }
    say qq{</div>};
} ## end for my $codepoint (@sorted_codepoints)

say '</BODY>';
say '</HTML>';
